%% Licensed under the Apache License, Version 2.0 (the "License"); you may
%% not use this file except in compliance with the License. You may obtain
%% a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% @author Marc Igeleke
%% @copyright 2019 Marc Igeleke
%% @doc Find duplicates in a directory based on file content.

-module(doppelgangerl).
-export([dedupe/1]).

-include_lib("kernel/include/file.hrl").

%% @spec (filename_all()) ->
%%      [{dupes, list()} | {errors,list()} | {deduped, list()}]
dedupe(Dir) ->
    dedupe(Dir, ".*").

dedupe(Dir, RegExp) ->
    [Dupes, Errors] = filelib:fold_files(Dir, RegExp, true, fun do_dedupe/2, [[],[]]),
    Deduped = [case DG of
		   {Dgst, dupes} ->
		       {Dgst, proplists:get_value(Dgst, Dupes)};
		   Unique ->
		       Unique
	       end || DG <- get()],
    [{dupes, Dupes},
     {errors, Errors},
     {deduped, Deduped}].

do_dedupe(File, [Dupes, Errs] = Acc) ->
    case file_crypto:hash(sha512, File) of
	{error, _} = Err -> [Dupes, [{Err, File}|Errs]];
	Dgst ->
	    case get(Dgst) of
		undefined -> put(Dgst,File),
			     Acc;
		dupes -> [[{Dgst,File}|Dupes], Errs];
		DupeFile -> put(Dgst, dupes),
			    [[{Dgst, DupeFile}, {Dgst, File} | Dupes], Errs]
	    end
    end.
