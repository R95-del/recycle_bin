# frozen_string_literal: true

require 'active_support/concern'

module RecycleBin
  module SoftDeletable
    extend ActiveSupport::Concern

    included do
      # Only add ActiveRecord scopes if this is an ActiveRecord model
      if self < ActiveRecord::Base
        # Add a default scope to exclude deleted records
        default_scope { where(deleted_at: nil) }

        # Scopes for querying deleted/not deleted records
        scope :deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
        scope :not_deleted, -> { where(deleted_at: nil) }
        scope :with_deleted, -> { unscope(where: :deleted_at) }
      end
    end

    class_methods do
      # Restore a record by ID (only for ActiveRecord models)
      def restore(id)
        unless self < ActiveRecord::Base
          raise NotImplementedError, 'restore method only available for ActiveRecord models'
        end

        with_deleted.find(id).restore
      end

      # Get all deleted records (only for ActiveRecord models)
      def deleted_records
        unless self < ActiveRecord::Base
          raise NotImplementedError, 'deleted_records method only available for ActiveRecord models'
        end

        deleted
      end
    end

    # Instance methods
    def soft_delete
      return false if deleted?

      if respond_to?(:update_column)
        update_column(:deleted_at, Time.current)
      elsif respond_to?(:deleted_at=)
        # For non-ActiveRecord objects, just set the attribute
        self.deleted_at = Time.current
      end
    end

    def restore
      return false unless deleted?

      if respond_to?(:update_column)
        update_column(:deleted_at, nil)
      elsif respond_to?(:deleted_at=)
        # For non-ActiveRecord objects, just set the attribute
        self.deleted_at = nil
      end
    end

    def deleted?
      respond_to?(:deleted_at) && deleted_at.present?
    end

    def destroy
      # Override destroy to use soft delete instead
      soft_delete
    end

    # For permanent deletion (use carefully!) - only for ActiveRecord
    def destroy!
      raise NotImplementedError, 'destroy! method only available for ActiveRecord models' unless respond_to?(:super)

      super # Call ActiveRecord's original destroy
    end

    # V1 helper for the trash controller
    def recyclable_title
      # Try common title fields safely
      return try(:title) if respond_to?(:title) && try(:title).present?
      return try(:name) if respond_to?(:name) && try(:name).present?
      return try(:email) if respond_to?(:email) && try(:email).present?

      "#{self.class.name} ##{id}"
    end
  end
end
