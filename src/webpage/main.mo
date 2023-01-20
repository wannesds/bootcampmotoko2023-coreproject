import Text "mo:base/Text";

import Http "types";


actor {
    //Yes, Iknow its the bare minimum, havent made any dao main funcs yet
    public type HttpRequest = Http.HttpRequest;
    public type HttpResponse = Http.HttpResponse;
    //code stable var that stores all passed proposals
    //code function which requires certain canister PrincipalID and proposal type OR just payload, 
    //and stores that in the stable var

    //make http show on webpage and replace body with last added (or all) proposal payload
    public query func http_request(req : HttpRequest) : async HttpResponse {
        return ({
            body = Text.encodeUtf8("Hello world!");
            headers = [];
            status_code = 200;
            streaming_strategy = null;
        })
    };
};