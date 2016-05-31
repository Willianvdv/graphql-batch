module GraphQL::Batch
  class Executor
    THREAD_KEY = :"#{name}.batched_queries"
    private_constant :THREAD_KEY

    def self.current
      Thread.current[THREAD_KEY] ||= new
    end

    attr_reader :loaders, :loading

    def initialize
      @loaders = {}
      @loading = false
    end

    def shift
      @loaders.shift.last
    end

    def tick
      with_loading(true) { shift.resolve }
    end

    def wait(promise)
      tick while promise.pending? && !loaders.empty?
      if promise.pending?
        promise.reject(BrokenPromiseError.new("Promise wasn't fulfilled after all queries were loaded"))
      end
    end

    def wait_all
      tick until loaders.empty?
    end

    def clear
      loaders.clear
    end

    def defer
      with_loading(false) { yield }
    end

    private

    def with_loading(loading)
      was_loading = @loading
      begin
        @loading = loading
        yield
      ensure
        @loading = was_loading
      end
    end
  end
end
