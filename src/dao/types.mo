import Nat "mo:base/Nat";
import List "mo:base/List";



module T {
  public type Balance = Nat;
  public type Account = { owner : Principal };
  public type CanisterPrincipal = Text;
  public type VotersList = List.List<Principal>;
  public type VotePower =  Nat;

  public type Status = {
    #Waiting;
    #Passed;
    #Rejected;
  };

  public type Proposal = {
    id: Nat;
    userPrincipal: Principal;
    payload: Text;
    voters: VotersList;
    yesVotes: VotePower;
    noVotes: VotePower;
    status: Status; 
  };
}