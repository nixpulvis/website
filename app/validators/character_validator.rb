# Depends on :server and :name to be present.
class CharacterValidator < ActiveModel::Validator
  def validate(record)
    begin
      character = WoW::CharacterProfile.new(record.server, record.name)
      record.update_attribute(:klass, character.lookup(:class))
      record.update_attribute(:level, character[:level])
    rescue WoW::APIError => e
      case e.message
      when /Realm/
        record.errors.add(:realm, "is invalid")
      when /Character/
        record.errors.add(:name, "not found")
      else
        record.errors.add(:base, "Error with Blizzard API")
      end
    end
  end
end