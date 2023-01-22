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
import Blob "mo:base/Blob";
import TrieMap "mo:base/TrieMap";
import Debug "mo:base/Debug";

import Typ "types";
import Utils "utils";

//TODO: streamline types and var names, need to make changes in frontend service callers for it
//TODO: remove/streamline w frontend error handling and group in a result enum
//TODO: joint yes + no votes in 1 type for cleaner code


//functions internally might use Prop instead of Proposal for cleaner shorter code
actor {

  let reqVotes : Typ.VotePower = 100 * 100000000;
  //webpageId = "qaa6y-5yaaa-aaaaa-aaafa-cai"; //LOCAL
  let webpageId : Typ.CanisterPrincipal = "lfanb-tyaaa-aaaap-aayma-cai"; //IC
  let icrcId : Typ.CanisterPrincipal = "db3eq-6iaaa-aaaah-abz6a-cai"; //MBT TOKEN

  let icrcActor = actor(icrcId) : actor { 
    icrc1_balance_of : (Typ.Account) -> async Typ.Balance
  };

  let webpageActor = actor(webpageId) : actor { 
    receive_Message : (Text) -> async Nat
  };
  
  // let webpageActor = actor(webpageCanId) : actor {  
  //   store : shared ({
  //     key : Text;
  //     content_type : Text;
  //     content_encoding : Text;
  //     content : [Nat8];
  //     sha256 : ?[Nat8];
  //   }) -> async ()
  // }; 


  //TODO: figure out what and how library to import for ICRCTypes (NatLabs or?)
  //prob have to vessel and setup local ledger stuff, check tomorrow Zane's answer
  //let mbtCanister = actor (mbtPrincipal) : ICRCTypes.TokenInterface;

  //STABLE STORES
  func natHash(n : Nat) : Hash.Hash { 
      Text.hash(Nat.toText(n));
  };
  
  stable var passedProposals : Nat = 0;
  stable var proposalIdCount : Nat = 0;

  stable var stableProposals : [(Nat, Typ.Proposal)] = [];

  let proposals = HashMap.fromIter<Nat, Typ.Proposal>(stableProposals.vals(), Iter.size(stableProposals.vals()), Nat.equal, natHash);

  //SYSTEM FUNCTIONS
  system func preupgrade() { 
    stableProposals := Iter.toArray(proposals.entries());
  };

  system func postupgrade() { 
    stableProposals := [];
  };
  
  //PRIVATE FUNCTIONS
  private func send_Message(message : Text) : async Nat {
    let size = await webpageActor.receive_Message(message);
    return size;
  };

  //PUBLIC FUNCTIONS
  public shared({caller}) func submit_proposal(payload: Text) : async {#Ok : Typ.Proposal; #Err : Text} {
    //1 auth


    //2 prepare data
    //could check description size or word count
    let minimumWords : Nat = 5;
    if (Utils.number_of_words(payload) < minimumWords) {
      return #Err("Seriously?, You should write atleast 5 words!");
    };
    let id : Nat = proposalIdCount;
    proposalIdCount += 1;

    let newProposal : Typ.Proposal = {
      id = id;
      userPrincipal = caller;
      payload = payload;
      voters = List.nil(); 
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
    // if (Principal.isAnonymous(caller)) {
    //   return #Err("You can't do this anonymously!");
    // }; //why this doesnt work ugh

    //2 query data
    let propRes : ?Typ.Proposal = proposals.get(proposal_id);
    
    //3 validate existence
    switch (propRes) {
      case (null) {
        return #Err("Strange, this proposal doesn't exist!");
        //could be removed since theres alrdy an error response on frontend, will have to check later
      };
      case (?prop) {
        //4b check if caller hasnt voted yet on this Proposal
        switch (List.find<Principal>(prop.voters, func (x) {x == caller})) {
          case (null) {};
          case (?_) return #Err("You can't vote twice for the same proposal!");
        };
        

        var voters_ : Typ.VotersList = List.push(caller, prop.voters);
        var status_ : Typ.Status = prop.status; //init var
        var yesVotes_ : Nat = prop.yesVotes;
        var noVotes_ : Nat = prop.noVotes;
        var power : Typ.VotePower = 0;

        //4c check the balance of caller , must be more than 1
        try {
          power := await get_balance(caller);
          //assert(1 <= power); //test if assert is needed here or not
        } catch err {
          return #Err("You don't have any tokens!");
        };

        //5 update the porposal data 
        //TODO : put these yes/no in 1 type
        switch(yes_or_no) {
          case (true) yesVotes_ += power;
          case (false) noVotes_ += power;
        };
        //6 check if prop status can pass OR reject, also mitigate any power overshoot
        if (yesVotes_ >= reqVotes) { 
          status_ := #Passed;
          yesVotes_ := reqVotes;
        } else if (noVotes_ >= reqVotes) {
          status_ := #Rejected;
          noVotes_ := reqVotes;
        };

        //6b add caller to List

        //build new prop
        let updatedProp : Typ.Proposal = {
            id = prop.id;
            userPrincipal = prop.userPrincipal;
            payload = prop.payload;
            voters = prop.voters; //add caller to this list/buffer
            yesVotes = yesVotes_;
            noVotes = noVotes_;
            status = status_;
        };

        //7 update post & confirm succes and return (the current votes?) , if no succes return error
        try {
          await async proposals.put(prop.id, updatedProp);
        } catch err {
          return #Err("Strange, could not vote on proposal : " # Error.message(err));
        };
        if (status_ == #Passed) {
          try {
            let c : Nat = await send_Message(prop.payload);
          } catch err {
            Debug.print("Sending proposal to the webpage has failed : " # Error.message(err));
          };
        };
        
        return #Ok(updatedProp.yesVotes, updatedProp.noVotes);
      };
    };
  };//end of vote function

  public query ({caller}) func get_proposal(proposalId : Nat) : async ?Typ.Proposal {
    //1. auth
      
    //2. query data
    let propRes : ?Typ.Proposal = proposals.get(proposalId);

    //3.return requested proposal
    return propRes;
  };
  
  public query func get_all_proposals() : async [Typ.Proposal] {
    return Iter.toArray(proposals.vals());
  };

  public func get_balance(caller : Principal) : async Typ.Balance {
    return await icrcActor.icrc1_balance_of({ owner = caller });
  };

};