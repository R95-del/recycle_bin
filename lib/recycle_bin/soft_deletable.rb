# frozen_string_literal: true

require 'active_support/concern'

module RecycleBin
  # SoftDeletable module provides soft delete functionality for ActiveRecord models.
  # Instead of permanently deleting records, it marks them as deleted by setting
  # a deleted_at timestamp, allowing for restoration and trash management.
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
        scope :only_deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
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

      # Find deleted records safely (bypasses default scope)
      def find_deleted
        unscoped.where.not(deleted_at: nil)
      end
    end

    # Instance methods
    def soft_delete
      return false if deleted?

      if respond_to?(:update_column)
        # Use update_column to bypass validations and callbacks
        update_column(:deleted_at, Time.current)
      elsif respond_to?(:deleted_at=)
        # For non-ActiveRecord objects, just set the attribute
        self.deleted_at = Time.current
        save if respond_to?(:save)
      end
    end

    def restore
      return false unless deleted?

      if respond_to?(:update_column)
        # Use update_column to bypass validations and callbacks
        update_column(:deleted_at, nil)
      elsif respond_to?(:deleted_at=)
        # For non-ActiveRecord objects, just set the attribute
        self.deleted_at = nil
        save if respond_to?(:save)
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
      raise NotImplementedError, 'destroy! method only available for ActiveRecord models' unless respond_to?(:delete)

      # Use delete to bypass callbacks and directly remove from database
      self.class.unscoped.where(id: id).delete_all
    end

    # Helper for the trash controller
    def recyclable_title
      # Try common title fields safely
      return try(:title) if respond_to?(:title) && try(:title).present?
      return try(:name) if respond_to?(:name) && try(:name).present?
      return try(:email) if respond_to?(:email) && try(:email).present?

      "#{self.class.name} ##{id}"
    end
  end
end
