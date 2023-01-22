import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export type Balance = bigint;
export type List = [] | [[Principal, List]];
export interface Proposal {
  'id' : bigint,
  'status' : Status,
  'noVotes' : VotePower,
  'yesVotes' : VotePower,
  'voters' : VotersList,
  'userPrincipal' : Principal,
  'payload' : string,
}
export type Status = { 'Passed' : null } |
  { 'Rejected' : null } |
  { 'Waiting' : null };
export type VotePower = bigint;
export type VotersList = [] | [[Principal, List]];
export interface _SERVICE {
  'get_all_proposals' : ActorMethod<[], Array<Proposal>>,
  'get_balance' : ActorMethod<[Principal], Balance>,
  'get_proposal' : ActorMethod<[bigint], [] | [Proposal]>,
  'submit_proposal' : ActorMethod<
    [string],
    { 'Ok' : Proposal } |
      { 'Err' : string }
  >,
  'vote' : ActorMethod<
    [bigint, boolean],
    { 'Ok' : [bigint, bigint] } |
      { 'Err' : string }
  >,
}
