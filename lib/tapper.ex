defmodule Tapper do
  @moduledoc """
  The high-level client API for Tapper.

  ## Example
  ```
  # start new trace (and span)
  id = Tapper.start(name: "main", type: :client, debug: true, annotations: Tapper.tag("a", "b"))

  # or join an existing one
  # id = Trapper.join(trace_id, span_id, parent_id, sample, debug, name: "main")

  # start child span
  id = Tapper.start_span(id, name: "call-out", annotations: [
    Tapper.wire_send(),
    Tapper.http_path("/resource/1234")
  ])

  # do something
  ...

  # tag current span with some additional metadata, e.g. when available
  Tapper.update_span(id, [
    :wire_recv, # equivalent to Tapper.wire_receive/0
    Tapper.tag("someId", someId),
  ])
  ...

  # end child span
  id = Tapper.finish_span(child_id, annotations: Tapper.http_status_code(200))

  Tapper.finish(span_id) # end trace
  ```

  ## Annotations and Updates

  Annotations are either *binary* annotations, which have a `type`, `key` and `value`, and an optional endpoint,
  or *event* annotations which have a key-like value, and an optional endpoint. Only event annotations have
  an associated timestamp (normally automatically generated by the API, or alternatively supplied to `update_span/3`).

  The helper functions in this module produce either a binary annotation or an event annotation, and can be
  passed through the `annotations` option on any of `start/1`, `join/6`, `start_span/2`, `finish_span/2`
  and `finish/2`, or as the second parameter of `update_span/3`. Note that for convenience, all these functions
  accept either a list of annotations, or a single annotation.

  For event annotations, instead of using the helper function, you can pass an atom, which results in an
  event annotation, with the default endpoint. i.e. the following are all equivalent in terms of the annotations
  they produce (but not, of course in other ways):

  ```
  Tapper.start_span(id, annotations: [Tapper.server_receive()])
  Tapper.start_span(id, annotations: Tapper.server_receive())
  Tapper.start_span(id, annotations: [:sr])
  Tapper.start_span(id, annotations: :sr)
  Tapper.update_span(id, [Tapper.server_receive()])
  Tapper.update_span(id, Tapper.server_receive())
  Tapper.update_span(id, :sr)
  Tapper.update_span(id, [:sr])
  ```

  | Helper | Kind | Value/Key | Short-code(s) |
  | ------ | ---- | ---------- | ---- |
  | `server_receive/0` | event | `sr` | `:sr`, `:server_recv` |
  | `server_send/0` | event | `ss` | `:ss`, `:server_send` |
  | `client_receive/0` | event | `cr` | `:cr`, `:client_recv` |
  | `client_send/0` | event | `cs` | `:cs`, `:server_send` |
  | `wire_send/0` | event | `ws` | `:ws`, `:wire_send` |
  | `wire_receive/0` | event | `wr` | `:wr`, `:wire_recv` |
  | `error/0` | event | `error` | `:error` |
  | `async/0` | event | `async` | N/A |
  | `annotation/2` | event | given value | N/A |
  | `client_address/1` | binary | `ca` | N/A |
  | `server_address/1` | binary | `sa` | N/A |
  | `http_host/1` | binary | `http.host` | N/A |
  | `http_method/1` | binary | `http.method` | N/A |
  | `http_path/1` | binary | `http.path` | N/A |
  | `http_url/1` | binary | `http.url` | N/A |
  | `http_status_code/1` | binary | `http.status_code` | N/A |
  | `http_request_size/1` | binary | `http.request_size` | N/A |
  | `http_response_size/1` | binary | `http.response_size` | N/A |
  | `sql_query/1` | binary | `sql.query` | N/A |
  | `error_message/1` | binary | `error` | N/A |
  | `tag/3` | binary | given key | N/A |
  | `binary_annotation/4` | binary | given key | N/A |

  The general functions, `annotation/2` and `binary_annotation/4` can be used to create any other type
  of annotation, and also allow a `Tapper.Endpoint` struct to be specified.

  ### Other update types with special meanings

  * `name/1` does not add an annotation, it sets the name of the span.
  * `async/0` adds an `async` event annotation, but also modifies the behaviour of Tapper to support
     asynchronous termination of spans. See `Tapper.Tracer.Timeout` for details.
  """

  @behaviour Tapper.Tracer.Api

  @binary_annotation_types [:string, :bool, :i16, :i32, :i64, :double, :bytes]

  alias Tapper.Tracer
  alias Tapper.Tracer.Api

  @spec start(opts :: Keyword.t) :: Tapper.Id.t
  defdelegate start(opts \\ []), to: Tracer

  @spec join(trace_id :: Tapper.TraceId.t,
    span_id :: Tapper.SpanId.t,
    parent_id :: Tapper.SpanId.t | :root,
    sample :: boolean(), debug :: boolean(),
    opts :: Keyword.t) :: Tapper.Id.t
  defdelegate join(trace_id, span_id, parent_id, sample, debug, opts \\ []), to: Tracer

  @spec finish(tapper_id :: Tapper.Id.t, opts :: Keyword.t) :: :ok
  defdelegate finish(id, opts \\ []), to: Tracer

  @spec start_span(tapper_id :: Tapper.Id.t, opts :: Keyword.t) :: Tapper.Id.t
  defdelegate start_span(id, opts \\ []), to: Tracer

  @spec finish_span(tapper_id :: Tapper.Id.t, opts :: Keyword.t) :: Tapper.Id.t
  defdelegate finish_span(id, opts \\ []), to: Tracer

  @spec update_span(tapper_id :: Tapper.Id.t, deltas :: Api.delta | [Api.delta], opts :: Keyword.t) :: Tapper.Id.t
  defdelegate update_span(id, deltas, opts \\ []), to: Tracer

  use Tapper.AnnotationHelpers
end
