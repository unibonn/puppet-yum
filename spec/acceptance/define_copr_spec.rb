require 'spec_helper_acceptance'

describe 'yum::copr define' do
  repo_filename = %w[6 7].include?(fact('os.release.major')) ? '_copr_copart-restic.repo' : '_copr:copr.fedorainfracloud.org:copart:restic.repo'
  context 'enable a repository' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-EOS
      yum::copr{ 'copart/restic':
        ensure => enabled,
      }
      EOS
      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end
    describe file("/etc/yum.repos.d/#{repo_filename}") do
      it { is_expected.to be_file }
      it { is_expected.to contain '[copr:copr.fedorainfracloud.org:copart:restic]' }
      it { is_expected.to contain 'enabled=1' }
    end
  end
  context 'disable a repository' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      pp = <<-EOS
      yum::copr{ 'copart/restic':
        ensure => disabled,
      }
      EOS
      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end
    describe file("/etc/yum.repos.d/#{repo_filename}") do
      if %w[6 7].include?(fact('os.release.major'))
        it { is_expected.not_to be_file }
      else
        it { is_expected.to be_file }
        it { is_expected.to contain '[copr:copr.fedorainfracloud.org:copart:restic]' }
        it { is_expected.to contain 'enabled=0' }
      end
    end
  end
  context 'remove a repository after adding it' do
    # Using puppet_apply as a helper
    it 'must work idempotently with no errors' do
      ppadd = <<-EOS
      yum::copr{ 'copart/restic':
        ensure => enabled,
      }
      EOS
      apply_manifest(ppadd, catch_failures: true)
      pp = <<-EOS
      yum::copr{ 'copart/restic':
        ensure => removed,
      }
      EOS
      # Run it twice and test for idempotency
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes:  true)
    end
    describe file("/etc/yum.repos.d/#{repo_filename}") do
      it { is_expected.not_to be_file }
    end
  end
end
