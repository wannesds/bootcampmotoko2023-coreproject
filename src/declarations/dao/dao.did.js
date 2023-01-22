export const idlFactory = ({ IDL }) => {
  const List = IDL.Rec();
  const Status = IDL.Variant({
    'Passed' : IDL.Null,
    'Rejected' : IDL.Null,
    'Waiting' : IDL.Null,
  });
  const VotePower = IDL.Nat;
  List.fill(IDL.Opt(IDL.Tuple(IDL.Principal, List)));
  const VotersList = IDL.Opt(IDL.Tuple(IDL.Principal, List));
  const Proposal = IDL.Record({
    'id' : IDL.Nat,
    'status' : Status,
    'noVotes' : VotePower,
    'yesVotes' : VotePower,
    'voters' : VotersList,
    'userPrincipal' : IDL.Principal,
    'payload' : IDL.Text,
  });
  const Balance = IDL.Nat;
  return IDL.Service({
    'get_all_proposals' : IDL.Func([], [IDL.Vec(Proposal)], ['query']),
    'get_balance' : IDL.Func([IDL.Principal], [Balance], []),
    'get_proposal' : IDL.Func([IDL.Nat], [IDL.Opt(Proposal)], ['query']),
    'submit_proposal' : IDL.Func(
        [IDL.Text],
        [IDL.Variant({ 'Ok' : Proposal, 'Err' : IDL.Text })],
        [],
      ),
    'vote' : IDL.Func(
        [IDL.Nat, IDL.Bool],
        [IDL.Variant({ 'Ok' : IDL.Tuple(IDL.Nat, IDL.Nat), 'Err' : IDL.Text })],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
