class Integrations::Facebook::CommentParser

    def initialize(value_json)
        @value = JSON.parse(value_json)['value']
    end

    def page_id
        @value['value']['page_id']
    end

    def post_id
        @value['value']['post_id']
    end

    def comment_id
        @value['value']['comment_id']
    end

    def from_id
        @value['value']['from']['id']
    end

    def text
        @value['value']['message']
    end
end