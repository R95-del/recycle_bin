# frozen_string_literal: true

module RecycleBin
  module SoftDeletable
    extend ActiveSupport::Concern

    included do
      # Add a default scope to exclude deleted records
      default_scope { where(deleted_at: nil) }

      # Scopes for querying deleted/not deleted records
      scope :deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
      scope :not_deleted, -> { where(deleted_at: nil) }
      scope :with_deleted, -> { unscope(where: :deleted_at) }
    end

    class_methods do
      # Restore a record by ID
      def restore(id)
        with_deleted.find(id).restore
      end

      # Get all deleted records
      def deleted_records
        deleted
      end
    end

    # Instance methods
    def soft_delete
      return false if deleted?
      update_column(:deleted_at, Time.current)
    end

    def restore
      return false unless deleted?
      update_column(:deleted_at, nil)
    end

    def deleted?
      deleted_at.present?
    end

    def destroy
      # Override destroy to use soft delete instead
      soft_delete
    end

    # For permanent deletion (use carefully!)
    def destroy!
      super # Call ActiveRecord's original destroy
    end

    # V1 helper for the trash controller
    def recyclable_title
      # Try common title fields
      title || name || email || "#{self.class.name} ##{id}"
    rescue NoMethodError
      "#{self.class.name} ##{id}"
    end
  end
end
