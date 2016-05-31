module GraphQL::Batch
  class Promise < ::Promise
    def wait
      Executor.current.wait(self)
    end

    def defer
      Executor.current.defer { yield }
    end
  end
end
