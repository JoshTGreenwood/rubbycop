# frozen_string_literal: true

require 'support/file_helper'
require 'rubbycop/rake_task'

describe RubbyCop::RakeTask do
  include FileHelper

  describe 'defining tasks' do
    it 'creates a rubbycop task' do
      described_class.new

      expect(Rake::Task.task_defined?(:rubbycop)).to be true
    end

    it 'creates a rubbycop:auto_correct task' do
      described_class.new

      expect(Rake::Task.task_defined?('rubbycop:auto_correct')).to be true
    end

    it 'creates a named task' do
      described_class.new(:lint_lib)

      expect(Rake::Task.task_defined?(:lint_lib)).to be true
    end

    it 'creates an auto_correct task for the named task' do
      described_class.new(:lint_lib)

      expect(Rake::Task.task_defined?('lint_lib:auto_correct')).to be true
    end
  end

  describe 'running tasks' do
    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
      Rake::Task['rubbycop'].clear if Rake::Task.task_defined?('rubbycop')
    end

    after do
      $stdout = STDOUT
      $stderr = STDERR
    end

    it 'runs with default options' do
      described_class.new

      cli = double('cli', run: 0)
      allow(RubbyCop::CLI).to receive(:new) { cli }
      expect(cli).to receive(:run).with([])

      Rake::Task['rubbycop'].execute
    end

    it 'runs with specified options if a block is given' do
      described_class.new do |task|
        task.patterns = ['lib/**/*.rb']
        task.formatters = ['files']
        task.fail_on_error = false
        task.options = ['--display-cop-names']
        task.verbose = false
      end

      cli = double('cli', run: 0)
      allow(RubbyCop::CLI).to receive(:new) { cli }
      options = ['--format', 'files', '--display-cop-names', 'lib/**/*.rb']
      expect(cli).to receive(:run).with(options)

      Rake::Task['rubbycop'].execute
    end

    it 'allows nested arrays inside formatters, options, and requires' do
      described_class.new do |task|
        task.formatters = [['files']]
        task.requires = [['library']]
        task.options = [['--display-cop-names']]
      end

      cli = double('cli', run: 0)
      allow(RubbyCop::CLI).to receive(:new) { cli }
      options = ['--format', 'files', '--require', 'library',
                 '--display-cop-names']
      expect(cli).to receive(:run).with(options)

      Rake::Task['rubbycop'].execute
    end

    it 'will not error when result is not 0 and fail_on_error is false' do
      described_class.new do |task|
        task.fail_on_error = false
      end

      cli = double('cli', run: 1)
      allow(RubbyCop::CLI).to receive(:new) { cli }

      expect { Rake::Task['rubbycop'].execute }.not_to raise_error
    end

    it 'exits when result is not 0 and fail_on_error is true' do
      described_class.new

      cli = double('cli', run: 1)
      allow(RubbyCop::CLI).to receive(:new) { cli }

      expect { Rake::Task['rubbycop'].execute }.to raise_error(SystemExit)
    end

    it 'uses the default formatter from .rubbycop.yml if no formatter ' \
       'option is given', :isolated_environment do
      create_file('.rubbycop.yml', <<-END.strip_indent)
        AllCops:
          DefaultFormatter: offenses
      END
      create_file('test.rb', '$:')

      described_class.new do |task|
        task.options = ['test.rb']
      end

      expect { Rake::Task['rubbycop'].execute }.to raise_error(SystemExit)

      expect($stdout.string).to eq(<<-END.strip_indent)
        Running RubbyCop...

        1  Style/SpecialGlobalVars
        --
        1  Total

      END
      expect($stderr.string.strip).to eq 'RubbyCop failed!'
    end

    context 'auto_correct' do
      it 'runs with --auto-correct' do
        described_class.new

        cli = double('cli', run: 0)
        allow(RubbyCop::CLI).to receive(:new) { cli }
        options = ['--auto-correct']
        expect(cli).to receive(:run).with(options)

        Rake::Task['rubbycop:auto_correct'].execute
      end

      it 'runs with with the options that were passed to its parent task' do
        described_class.new do |task|
          task.patterns = ['lib/**/*.rb']
          task.formatters = ['files']
          task.fail_on_error = false
          task.options = ['-D']
          task.verbose = false
        end

        cli = double('cli', run: 0)
        allow(RubbyCop::CLI).to receive(:new) { cli }
        options = ['--auto-correct', '--format', 'files', '-D', 'lib/**/*.rb']
        expect(cli).to receive(:run).with(options)

        Rake::Task['rubbycop:auto_correct'].execute
      end
    end
  end
end