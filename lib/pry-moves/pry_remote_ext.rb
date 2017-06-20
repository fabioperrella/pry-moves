require 'pry' unless defined? Pry
require 'pry-remote'

module PryRemote
  class Server
    # Override the call to Pry.start to save off current Server, pass a
    # pry_remote flag so pry-moves knows this is a remote session, and not kill
    # the server right away
    def run
      if PryMoves.current_remote_server
        raise 'Already running a pry-remote session!'
      else
        PryMoves.current_remote_server = self
      end

      setup
      Pry.start @object, {
        :input  => client.input_proxy,
        :output => client.output,
        :pry_remote => true
      }
    end

    # Override to reset our saved global current server session.
    alias_method :teardown_without_pry_nav, :teardown
    def teardown_with_pry_nav
      teardown_without_pry_nav
      PryMoves.current_remote_server = nil
    end
    alias_method :teardown, :teardown_with_pry_nav
  end
end

# Ensure cleanup when a program finishes without another break. For example,
# 'next' on the last line of a program never hits the tracer proc, and thus
# PryMoves::Tracer#run doesn't have a chance to cleanup.
at_exit do
  set_trace_func nil
  if PryMoves.current_remote_server
    PryMoves.current_remote_server.teardown
  end
end
