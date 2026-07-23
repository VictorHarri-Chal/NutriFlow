module ValidatesSharedOwner
  extend ActiveSupport::Concern

  class_methods do
    # Validates that `child` (an association on this record) belongs to the same
    # user as `owner` (another association, or a lambda evaluated in the record's
    # context) — both must expose #user_id. Closes IDOR-style gaps where a
    # client-supplied foreign key could otherwise reference another user's
    # resource (e.g. a Food attached to someone else's Recipe).
    def validates_shared_owner(child, owner:, **validation_options)
      method_name = :"#{child}_belongs_to_user"

      define_method(method_name) do
        child_record = send(child)
        owner_record = owner.is_a?(Proc) ? instance_exec(&owner) : send(owner)
        return unless child_record && owner_record

        errors.add(child, :invalid) unless owner_record.user_id == child_record.user_id
      end
      private method_name

      validate method_name, **validation_options
    end
  end
end
