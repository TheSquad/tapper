defmodule Tracer.TraceTest do
  @moduledoc false

  use ExUnit.Case

  import Test.Helper.Server

  alias Tapper.Tracer.Trace

  import Tapper.Timestamp, only: [instant: 0, incr: 2]

  test "parents of root span" do
    root_span = %{span(1, instant(), 100) | parent_id: :root}
    trace = trace([root_span])

    assert Trace.parents_of(trace, root_span.id) == []
  end

  test "parents of child span" do

    root_span = %{span(1, instant(), 100) | parent_id: :root}
    child_span = %{span(2, incr(instant(), 10), 100) | parent_id: root_span.id}

    trace = trace([child_span, root_span])

    assert Trace.parents_of(trace, child_span.id) == [1]
  end

  test "parents of grand-span" do

    root_span = %{span(1, instant(), 100) | parent_id: :root}
    child_span = %{span(2, incr(instant(), 10), 100) | parent_id: root_span.id}
    grand_span = %{span(3, incr(instant(), 20), 100) | parent_id: child_span.id}

    trace = trace([grand_span, child_span, root_span])

    assert Trace.parents_of(trace, grand_span.id) == [2, 1]
  end

end
