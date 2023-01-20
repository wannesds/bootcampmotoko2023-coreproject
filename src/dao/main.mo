import Nat8 "mo:base/Nat8";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Text "mo:base/Text";
import List "mo:base/List";

import Utils "utils";

//TODO: streamline types and var names, need to make changes in frontend service callers for it


//functions internally might use Prop instead of Proposal for cleaner shorter code
actor {

  type Proposal = {
    id: Int;
    userPrincipal: Principal;
    payload: Text;
    voters: List.List<Principal>;
    yesVotes: Nat;
    noVotes: Nat;
    passed: Bool; 
  };

  var proposals = HashMap.HashMap<Int, Proposal>(1, Int.equal, Hash.hash);
  
  stable var proposalIdCount : Int = 0;
  stable var nextProposalId : Int = 0;


  public shared({caller}) func submit_proposal(payload: Text) : async {#Ok : Proposal; #Err : Text} {
    //1 auth
    //check if caller is not anonymous?

    //2 prepare data
    //could check description size or word count
    let minimumWords : Nat = 5;
    if (Utils.number_of_words(payload) < minimumWords) {
      return #Err("You should write atleast 5 words");
    };
    let id : Int = proposalIdCount;
    proposalIdCount += 1;

    let newProposal : Proposal = {
      id = id;
      userPrincipal = caller;
      payload = payload;
      voters = List.nil(); //might change into a buffer bcs lists make me not happy
      yesVotes = 0;
      noVotes = 0;
      passed = false;
    };

    //3 create post
    try {
      await async proposals.put(id, newProposal);
    } catch err {
      return #Err("Strange, could not create proposal : " # Error.message(err));
    };

    //4 return confirmation 
    return #Ok(newProposal);
  };

  public shared({caller}) func vote(proposal_id : Int, yes_or_no : Bool) : async {#Ok : (Nat, Nat); #Err : Text} {
    //1 auth

    //2 query data
    let propRes : ?Proposal = proposals.get(proposal_id);
    
    //3 validate existence
    switch (propRes) {
      case (null) {
        return #Err("Strange, This proposal doesn't exist");
      };
      case (?cProp) {
        //4 validate if caller hasnt voted yet on this Proposal

        //5 update the porposal data
        var yes : Nat = 0;
        var no : Nat = 0;
        switch(yes_or_no) {
          case (true) yes := 1;
          case (false) no := 1;
        };
        let updatedProp : Proposal = {
            id = cProp.id;
            userPrincipal = cProp.userPrincipal;
            payload = cProp.payload;
            voters = cProp.voters; //add caller to this list/buffer
            yesVotes = cProp.yesVotes + yes ;
            noVotes = cProp.noVotes + no;
            passed = cProp.passed;
        };
        //I should find out if this or similar is possible, cant remember, would make it easier and less code
        //cProp.yesVotes += 1; and then update the cProp without having to make a new Prop

        //6 update post & confirm succes and return (the current votes?) , if no succes return error
        try {
          await async proposals.put(cProp.id, updatedProp);
        } catch err {
          return #Err("Strange, Could not vote on proposal : " # Error.message(err));
        };

        //7 check if prop can be 'passed' to true, if the case then update prop passed , and call function to send prop data to Webpage.
        
        return #Ok(updatedProp.yesVotes, updatedProp.noVotes);
        
        
      };
    };

    
    
  };

  public query func get_proposal(id : Int) : async ?Proposal {
    //1. auth

    //2. query data
    let propRes : ?Proposal = proposals.get(id);

    //3.return requested proposal
    return propRes;
  };
  
  public query func get_all_proposals() : async [(Int, Proposal)] {
    return []
  };
};