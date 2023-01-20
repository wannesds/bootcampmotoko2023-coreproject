import Nat8 "mo:base/Nat8";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Principal "mo:base/Principal";

actor {
    type Proposal = {
        id: Int;
        userPrincipal: Principal;
        description: Text;
        //votes: Nat;
    };

    var proposals = HashMap.HashMap<Int, Proposal>(1, Int.equal, Hash.hash);

    stable var proposalIdCount : Int = 0;


    public shared({caller}) func submit_proposal(this_payload : Text) : async {#Ok : Proposal; #Err : Text} {

        let id : Int = proposalIdCount;
        proposalIdCount += 1;

        proposals.put(id, this_payload, caller????);
        
        return #Err("Not implemented yet");
    };

    public shared({caller}) func vote(proposal_id : Int, yes_or_no : Bool) : async {#Ok : (Nat, Nat); #Err : Text} {
        return #Err("Not implemented yet");
    };

    public query func get_proposal(id : Int) : async ?Proposal {
        return null
    };
    
    public query func get_all_proposals() : async [(Int, Proposal)] {
        return []
    };
};