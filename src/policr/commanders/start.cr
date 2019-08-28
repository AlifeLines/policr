module Policr
  enum PayloadTarget
    Unknown; Vaqm
  end
  commander Start do
    def handle(msg, from_nav)
      chat_id = msg.chat.id

      payload =
        if (text = msg.text) && (args = text.split(" ")) && args.size > 1
          args[1]
        end
      if payload
        spawn bot.delete_message chat_id, msg.message_id
        forward_to payload, chat_id
      else
        text = t "start"
        bot.send_message chat_id, text
      end
    end

    def forward_to(payload, chat_id)
      if md = /^([^_]+)_(.+)$/.match payload
        key = md[1]
        data = md[2]
        case key
        when "vaqm"
          id = data.to_i
          if q = Model::Question.find(id)
            text = create_voting_apply_quiz_question_text q
            markup = create_voting_apply_quiz_question_markup q
            if sended_msg = bot.send_message chat_id, text, reply_markup: markup
              Cache.carving_voting_apply_quiz_question_msg chat_id, sended_msg.message_id, id
            end
          end
        end
      end
    end

    def create_voting_apply_quiz_question_text(question : Model::Question)
      answers_s = question.answers.map do |a|
        make_icon = ->{
          a.corrected ? "√" : "×"
        }
        "#{make_icon.call} #{a.name}"
      end.join("\n")
      t "voting.apply_quiz_question", {
        title:   question.title,
        desc:    question.desc,
        note:    question.note,
        answers: answers_s,
      }
    end

    def create_voting_apply_quiz_question_markup(question : Model::Question)
      make_btn = ->(action : String) {
        callback_data = "VotingApplyQuiz:question:#{action}:#{question.id}"
        Button.new(text: t("voting.apply_quiz.question.#{action}"), callback_data: callback_data)
      }
      markup = Markup.new
      buttons = Array(Button).new
      buttons << make_btn.call("disable") if question.enabled
      buttons << make_btn.call("enable") unless question.enabled
      buttons << make_btn.call("delete")
      markup << buttons

      markup
    end
  end
end
