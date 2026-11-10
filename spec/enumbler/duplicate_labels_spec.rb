# frozen_string_literal: true

# Models for `enumbler_allow_duplicate_labels`.  This file loads before
# spec/enumbler_spec.rb (and so before ApplicationRecord), so the models
# include Enumbler on ActiveRecord::Base directly.
ActiveRecord::Schema.define do
  # No unique index on label: labels repeat here by design.
  create_table :topics, force: true do |t|
    t.string :label, null: false
  end

  create_table :lessons, force: true do |t|
    t.references :topic, foreign_key: true, null: false
  end
end

class Topic < ActiveRecord::Base
  include Enumbler
  include Enumbler::Enabler

  enumbler_allow_duplicate_labels

  enumble :k12_classroom, 17, label: "Classroom"
  enumble :science, 20, label: "Science"
  enumble :higher_ed_classroom, 34, label: "Classroom"
  # A label that is also another enumble's enum name.
  enumble :tutoring, 40, label: "science"
end

class Lesson < ActiveRecord::Base
  include Enumbler

  enumbled_to :topic
end

RSpec.describe Enumbler::Enabler, "duplicate labels" do
  def enumbler_model(&)
    Class.new(ActiveRecord::Base) do
      self.table_name = "topics"
      include Enumbler::Enabler

      class_eval(&)
    end
  end

  describe "with the option off (the default)" do
    it "reports that duplicate labels are not allowed" do
      expect(enumbler_model { enumble :a, 1 }.enumbler_allow_duplicate_labels?).to be false
    end

    it "rejects a repeated label" do
      expect do
        enumbler_model do
          enumble :a, 1, label: "Classroom"
          enumble :b, 2, label: "Classroom"
        end
      end.to raise_error(Enumbler::Error, /twice/)
    end

    it "rejects a repeated enum or id" do
      expect { enumbler_model { enumble(:a, 1) && enumble(:a, 2) } }.to raise_error(Enumbler::Error, /twice/)
      expect { enumbler_model { enumble(:a, 1) && enumble(:b, 1) } }.to raise_error(Enumbler::Error, /twice/)
    end

    it "returns the first match for a String that matches a label and an enum name" do
      model = enumbler_model do
        enumble :tutoring, 1, label: "science"
        enumble :science, 2, label: "Science!"
      end

      expect(model.find_enumble("science").enum).to eq :tutoring
    end

    it "keeps label-only Enumble equality" do
      expect(Enumbler::Enumble.new(:a, 1, label: "x")).to eq Enumbler::Enumble.new(:b, 2, label: "x")
    end
  end

  describe "with the option on" do
    before { Topic.seed_the_enumbler! }

    it "reports that duplicate labels are allowed" do
      expect(Topic.enumbler_allow_duplicate_labels?).to be true
    end

    it "accepts enumbles that share a label" do
      expect(Topic.enumbles.map(&:label)).to eq %w[Classroom Science Classroom science]
    end

    it "still rejects a repeated enum or id" do
      expect { Topic.enumble(:science, 99) }.to raise_error(Enumbler::Error, /twice/)
      expect { Topic.enumble(:art, 17) }.to raise_error(Enumbler::Error, /twice/)
    end

    it "must be declared before the first enumble" do
      expect do
        enumbler_model do
          enumble :a, 1
          enumbler_allow_duplicate_labels
        end
      end.to raise_error(Enumbler::Error, /before its first `enumble`/)
    end

    it "can be passed false to keep the default" do
      model = enumbler_model do
        enumbler_allow_duplicate_labels false
        enumble :a, 1
      end

      expect(model.enumbler_allow_duplicate_labels?).to be false
    end

    it "keeps constants, shortcuts, predicates and graphql_enum per enum" do
      expect([Topic::K12_CLASSROOM, Topic::HIGHER_ED_CLASSROOM]).to eq [17, 34]
      expect(Topic.higher_ed_classroom).to eq Topic.find(34)
      expect(Topic.higher_ed_classroom).to be_higher_ed_classroom
      expect(Topic.higher_ed_classroom).to be_not_k12_classroom
      expect(Topic.k12_classroom(:graphql_enum)).to eq "K12_CLASSROOM"
      expect(Topic.higher_ed_classroom.to_s).to eq "Classroom"
    end

    it "seeds every enumble, labels and all" do
      expect(Topic.order(:id).pluck(:id, :label)).to eq(
        [[17, "Classroom"], [20, "Science"], [34, "Classroom"], [40, "science"]],
      )
    end

    it "does not treat Enumbles with the same label as equal" do
      expect(Topic.k12_classroom(:enumble)).not_to eq Topic.higher_ed_classroom(:enumble)
      expect(Topic.k12_classroom(:enumble)).not_to eql Topic.higher_ed_classroom(:enumble)
      expect(Topic.k12_classroom(:enumble)).to eq Topic.k12_classroom(:enumble)
    end

    it "finds by id, symbol, Enumble, and record as before" do
      expect(Topic.find_enumbles(34, :k12_classroom).map(&:id)).to eq [34, 17]
      expect(Topic.find_enumble(Topic.higher_ed_classroom(:enumble)).id).to eq 34
      expect(Topic.find_enumble(Topic.higher_ed_classroom).id).to eq 34
    end

    it "resolves a String that matches an enum name" do
      expect(Topic.find_enumble("higher_ed_classroom").id).to eq 34
      expect(Topic.find_enumble("HIGHER_ED_CLASSROOM").id).to eq 34
      expect(Topic.id_from_enumbler!("k12_classroom", case_sensitive: true)).to eq 17
    end

    it "prefers an enum-name match over a label match" do
      # "science" is :science's enum and :tutoring's label (and, ignoring case,
      # :science's label too).
      expect(Topic.find_enumble("science").enum).to eq :science
    end

    it "resolves a String that matches exactly one label" do
      expect(Topic.find_enumble("Science", case_sensitive: true).enum).to eq :science
    end

    it "returns nil (or raises when asked) for a String that matches nothing" do
      expect(Topic.find_enumble("Art")).to be_nil
      expect(Topic.find_enumble("classroom", case_sensitive: true)).to be_nil
      expect { Topic.find_enumble!("Art") }.to raise_error(Enumbler::Error, /Unable to find/)
    end

    it "raises for a String that matches more than one label, even without raise_error" do
      expect { Topic.find_enumble("Classroom") }.to raise_error(
        Enumbler::AmbiguousLabelError,
        'Topic has more than one enumble labeled "Classroom" (:k12_classroom, :higher_ed_classroom); ' \
        "look it up by enum or id instead.",
      )
      expect { Topic.find_enumble("classroom") }.to raise_error(Enumbler::AmbiguousLabelError)
      expect { Topic.find_enumble!("Classroom") }.to raise_error(Enumbler::AmbiguousLabelError)
      expect { Topic.find_enumbles(:science, "Classroom") }.to raise_error(Enumbler::AmbiguousLabelError)
      expect { Topic.ids_from_enumbler("Classroom") }.to raise_error(Enumbler::AmbiguousLabelError)
      expect { Topic.id_from_enumbler!("Classroom") }.to raise_error(Enumbler::AmbiguousLabelError)
    end

    it "raises the ambiguity from find_by_enumble rather than RecordNotFound" do
      expect { Topic.find_by_enumble("Classroom") }.to raise_error(Enumbler::AmbiguousLabelError)
      expect { Topic.find_by_enumble!("Classroom") }.to raise_error(Enumbler::AmbiguousLabelError)
      expect(Topic.find_by_enumble("higher_ed_classroom")).to eq Topic.find(34)
    end

    it "tries an exact-case match before a case-insensitive one" do
      model = enumbler_model do
        enumbler_allow_duplicate_labels
        enumble :upper, 1, label: "Classroom"
        enumble :lower, 2, label: "classroom"
        enumble :shouty, 3, label: "CLASSROOM"
      end

      expect(model.find_enumble("Classroom").enum).to eq :upper
      expect(model.find_enumble("classroom").enum).to eq :lower
      expect { model.find_enumble("ClassRoom") }.to raise_error(Enumbler::AmbiguousLabelError)
    end

    it "prefers an exact-case label over a case-insensitive enum name" do
      model = enumbler_model do
        enumbler_allow_duplicate_labels
        enumble :art, 1, label: "History"
        enumble :history, 2, label: "Art"
      end

      expect(model.find_enumble("Art").enum).to eq :history
      expect(model.find_enumble("art").enum).to eq :art
    end

    it "does not take the flag from an attribute of the same name" do
      enumble = Enumbler::Enumble.new(:a, 1, label: "x", allow_duplicate_labels: true)

      expect(enumble.allow_duplicate_labels?).to be false
      expect(enumble.attributes).to include(allow_duplicate_labels: true)
    end

    it "makes AmbiguousLabelError an Enumbler::Error" do
      expect { Topic.find_enumble("Classroom") }.to raise_error(Enumbler::Error)
    end

    it "applies the same rules to enumbled_to scopes" do
      lesson = Lesson.create!(topic: Topic.higher_ed_classroom)

      expect(Lesson.topic("higher_ed_classroom")).to eq [lesson]
      expect(Lesson.topic(:higher_ed_classroom, 17)).to eq [lesson]
      expect(lesson.topic_label).to eq "Classroom"
      expect(lesson.topic_enum).to eq :higher_ed_classroom
      expect { Lesson.topic("Classroom") }.to raise_error(Enumbler::AmbiguousLabelError)
    end
  end
end
