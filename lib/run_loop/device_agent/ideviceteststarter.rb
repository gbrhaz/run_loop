module RunLoop
  # @!visibility private
  module DeviceAgent
    # @!visibility private
    #
    # A wrapper around the test-control binary.
    class IDeviceTestStarter < RunLoop::DeviceAgent::LauncherStrategy

      require "fileutils"
      require "run_loop/shell"
      include RunLoop::Shell

      def self.log_file
        path = File.join(LauncherStrategy.dot_dir, "ideviceteststarter.log")
        FileUtils.touch(path) if !File.exist?(path)
        path
      end

      def runner
        @runner ||= RunLoop::DeviceAgent::Runner.new(device)
      end

      def name
        :ideviceteststarter
      end

      def launch(options)

        install_timeout = options[:device_agent_install_timeout]

        if device.simulator?
          raise ArgumentError, "Cannot launch tests on Simulators"
        end

        RunLoop::DeviceAgent::Frameworks.instance.install
        cmd = RunLoop::DeviceAgent::IOSDeviceManager.ios_device_manager


        shell_options = {:log_cmd => true, :timeout => install_timeout}

        args = [
          cmd, "install", runner.runner, "--device-id", device.udid
        ]

        hash = run_shell_command(args, shell_options)

        if hash[:exit_status] != 0
          raise RuntimeError, %Q[

Could not install #{runner.runner}.  iOSDeviceManager says:

#{hash[:out]}

          ]
        end

        cmd = "/usr/local/bin/ideviceteststarter"

        #aut = "/Users/moody/Downloads/3cd5e00d-e83a-442c-934b-9d6fafb843d4/Payload/Headspace.app"

        args = [
          "--uuid", device.udid, "-vvvv"
        ]

        log_file = IDeviceTestStarter.log_file
        FileUtils.rm_rf(log_file)
        FileUtils.touch(log_file)

        env = {
          # zsh support
          "CLOBBER" => "1"
        }

        options = {:out => log_file, :err => log_file}
        RunLoop.log_unix_cmd("#{cmd} #{args.join(" ")} >& #{log_file}")

        pid = Process.spawn(env, cmd, *args, options)
        Process.detach(pid)

        pid.to_i
      end
    end
  end
end
