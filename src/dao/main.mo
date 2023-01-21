import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Text "mo:base/Text";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Float "mo:base/Float";


import Utils "utils";
import Debug "mo:base/Debug";


//TODO: add checks to see that caller is not anonymous
//TODO: add check to see if caller hasnt voted on related proposal yet

//TODO SECONDARY
//TODO: streamline types and var names, need to make changes in frontend service callers for it
//TODO: remove/streamline w frontend error handling and group in a result enum
//TODO: joint yes + no votes in 1 type for cleaner code
//TODO: seperate types file

//functions internally might use Prop instead of Proposal for cleaner shorter code
actor {
  

  type Status = {
		#Waiting;
		#Passed;
		#Rejected;
	};

  type VotersList = List.List<Principal>;

  type Proposal = {
    id: Nat;
    userPrincipal: Principal;
    payload: Text;
    voters: VotersList;
    yesVotes: Nat;
    noVotes: Nat;
    status: Status; 
  };

  let icrcCanId = "db3eq-6iaaa-aaaah-abz6a-cai";
  let webpageCanId = "qaa6y-5yaaa-aaaaa-aaafa-cai";

  //(Thanks to Capuzr for helping me out on how it worked)
  let mbtActor = actor(icrcCanId) : actor {  
    store : shared ({
      key : Text;
      content_type : Text;
      content_encoding : Text;
      content : [Nat8];
      sha256 : ?[Nat8];
    }) -> async ()
  };

  // let icrcActor = actor(mbtCanId) : actor { 
  //   balance_of: () -> async ()
  // };

  let webpageActor : actor { receive_Message : (Text) -> async Nat } = actor (webpageCanId); 
  let icrcActor : actor { 
    balance_of:() -> async ();
    max_supply:() -> async (Nat);
  } = actor (icrcCanId);

  public func get_max_supply() : async Nat {
    let size = await icrcActor.max_supply();
    return size;
  };
  
  //TODO: figure out what and how library to import for ICRCTypes (NatLabs or?)
  //prob have to vessel and setup local ledger stuff, wait for answer Zane
  //let mbtCanister = actor (mbtPrincipal) : ICRCTypes.TokenInterface;

  //STORES
  //experimental, doesnt work as intended yet
  func natHash(n : Nat) : Hash.Hash { 
      Text.hash(Nat.toText(n));
  };

  stable var stableProposals : [(Nat, Proposal)] = [];

  let proposals = HashMap.fromIter<Nat, Proposal>(stableProposals.vals(), Iter.size(stableProposals.vals()), Nat.equal, natHash);
  system func preupgrade() { stableProposals := Iter.toArray(proposals.entries()) };
  system func postupgrade() { stableProposals := [] };
  
  //var proposals = HashMap.HashMap<Nat, Proposal>(1, Nat.equal, Hash.hash);
  
  stable var proposalIdCount : Nat = 0;

  //PRIVATE FUNCS
  private func send_Message(message : Text) : async Nat {
    let size = await webpageActor.receive_Message(message);
    return size
  };

  // private func balance_of(caller : Principal) : async Nat {
  //   let size = await icrcActor.balance_of({accounts}: mbtActor, caller);
  //   return size;
  // };

  //FUNCS
  public shared({caller}) func submit_proposal(payload: Text) : async {#Ok : Proposal; #Err : Text} {
    //1 auth
    //check if caller is not anonymous?

    //2 prepare data
    //could check description size or word count
    let minimumWords : Nat = 5;
    if (Utils.number_of_words(payload) < minimumWords) {
      return #Err("Seriously?, You should write atleast 5 words");
    };
    let id : Nat = proposalIdCount;
    proposalIdCount += 1;

    let newProposal : Proposal = {
      id = id;
      userPrincipal = caller;
      payload = payload;
      voters = List.nil(); //might change into a buffer bcs lists make me not happy
      yesVotes = 0;
      noVotes = 0;
      status = #Waiting;
    };

    //3 create postt
    try {
      await async proposals.put(id, newProposal);
    } catch err {
      return #Err("Strange, could not create proposal: " # Error.message(err));
    };

    //4 return confirmation 
    return #Ok(newProposal);
  };

  public shared({caller}) func vote(proposal_id : Nat, yes_or_no : Bool) : async {#Ok : (Nat, Nat); #Err : Text} {
    //1 auth

    //2 query data
    let propRes : ?Proposal = proposals.get(proposal_id);
    
    //3 validate existence
    switch (propRes) {
      case (null) {
        return #Err("Strange, this proposal doesn't exist");
        //could be reomved since theres alrdy an error response on frontend, will have to check later
      };
      case (?cProp) {
        //4a check if caller hasnt voted yet on this Proposal

        //4b check the balance of caller , must be more than 1
        //let icrc_canister : = actor ("db3eq-6iaaa-aaaah-abz6a-cai");
        //let mbtBalance = Float.fromInt(await icrc_canister.icrc1_balance_of({ owner = user; subaccount = null }));
        let power : Nat = 1;//MBT balane of caller & >= 1 
        //5 update the porposal data 
        var yes : Nat = 0;
        var no : Nat = 0;
        switch(yes_or_no) {
          case (true) yes := power;
          case (false) no := power;
        };
        let updatedProp : Proposal = {
            id = cProp.id;
            userPrincipal = cProp.userPrincipal;
            payload = cProp.payload;
            voters = cProp.voters; //add caller to this list/buffer
            yesVotes = cProp.yesVotes + yes ;
            noVotes = cProp.noVotes + no;
            status = cProp.status;
        };
        //I should find out if this or similar is possible, cant remember, would make it easier and less code
        //cProp.yesVotes += 1; and then update the cProp without having to make a new Prop

        //6 update post & confirm succes and return (the current votes?) , if no succes return error
        try {
          await async proposals.put(cProp.id, updatedProp);
        } catch err {
          return #Err("Strange, could not vote on proposal : " # Error.message(err));
        };


        //7 check if prop status can pass OR reject,
        //and if passed: send Proposal to Webpage
        
        return #Ok(updatedProp.yesVotes, updatedProp.noVotes);
      };
    };

  };

  public query func get_proposal(proposalId : Nat) : async ?Proposal {
    //1. auth

    //2. query data
    let propRes : ?Proposal = proposals.get(proposalId);

    //3.return requested proposal
    return propRes;
  };
  
  public query func get_all_proposals() : async [Proposal] {
    return Iter.toArray(proposals.vals());
  };



 
};