import Nat8 "mo:base/Nat8";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Text "mo:base/Text";
import List "mo:base/List";

import Utils "utils";

actor {

  type Proposal = {
    id: Int;
    userPrincipal: Principal;
    payload: Text;
    voters: List.List<Principal>;
    yesVotes: Nat;
    noVotes: Nat;
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
    let propData : Proposal = {
      id = id;
      userPrincipal = caller;
      payload = payload;
      voters = List.nil();
      yesVotes = 0;
      noVotes = 0;
    };

    //3 create post
    try {
      await async proposals.put(id, propData);
    } catch err {
      return #Err("Something went wrong : " # Error.message(err));
    };

    //4 return confirmation 
    return #Ok(propData);
  };

  public shared({caller}) func vote(proposal_id : Int, yes_or_no : Bool) : async {#Ok : (Nat, Nat); #Err : Text} {
    //1 auth

    //2
    //ZZZZzzzzzz😴

    
    return #Err("Not implemented yet");
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