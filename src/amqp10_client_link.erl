-module(amqp10_client_link).

-include("amqp10_client.hrl").
-include("rabbit_amqp1_0_framing.hrl").

-export([
         sender/3,
         receiver/3,
         send/2,
         get/1
        ]).

-type message() :: term().

-record(link_ref, {role :: sender | receiver,session :: pid(),
                   link_handle :: non_neg_integer(), link_name :: binary()}).
-opaque link_ref() :: #link_ref{}.

-export_type([link_ref/0,
              message/0]).

get(#link_ref{role = receiver, session = Session, link_handle = Handle}) ->
    %flow 1
    Flow = #'v1_0.flow'{link_credit = {uint, 1}},
    ok = amqp10_client_session:flow(Session, Handle, Flow).
    % wait for transfer


-spec send(link_ref(), message()) -> ok.
send(#link_ref{role = sender, session = Session, link_handle = Handle},
     Message) ->
    Transfer = #'v1_0.transfer'{handle = {uint, Handle}, settled = true},
    Payload = #'v1_0.data'{content = Message},
    ok = amqp10_client_session:transfer(Session, Transfer, Payload),
    ok.

-spec sender(pid(), binary(), binary()) -> link_ref().
sender(Session, Name, Address) ->
    Source = #'v1_0.source'{},
    Target = #'v1_0.target'{address = {utf8, Address}},
    {ok, Attach} = amqp10_client_session:attach(Session, Name, sender, Source,
                                                Target),
    {ok, #link_ref{role = sender, session = Session, link_name = Name,
                   link_handle = Attach}}.


-spec receiver(pid(), binary(), binary()) -> link_ref().
receiver(Session, Name, Address) ->
    Source = #'v1_0.source'{address = {utf8, Address}},
    Target = #'v1_0.target'{},
    {ok, Attach} = amqp10_client_session:attach(Session, Name, receiver, Source,
                                                Target),
    {ok, #link_ref{role = receiver, session = Session, link_name = Name,
                   link_handle = Attach}}.


