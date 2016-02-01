class InternalUserPolicy < ApplicationPolicy

  INTERNAL_IPS = (ENV['FHLB_INTERNAL_IPS'] || '').split.freeze

  def access?
    if user.intranet_user?
      (self.class.cidrs.find { |cidr| cidr.include?(record.remote_ip) }).present? || user.roles.include?(User::Roles::USER_WITH_EXTERNAL_ACCESS)
    else
      true
    end
  end

  def self.cidrs
    @@cidrs
  end

  def self.build_cidrs
    (INTERNAL_IPS.collect { |cidr| IPAddr.new(cidr) }).freeze
  end

  private_class_method :build_cidrs
  @@cidrs = build_cidrs

end