class Integrations::Facebook::CommentCreator
    attr_reader :comment

    def initialize(comment)
        @comment = comment
    end

    def perform
        builder = Messages::Facebook::CommentBuilder.new(@comment)
        builder.perform
    end
end