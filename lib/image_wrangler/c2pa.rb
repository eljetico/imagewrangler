# frozen_string_literal: true

require "open3"

module ImageWrangler
  class C2pa
    VALIDATION_SUCCESS_STRINGS = ["accessible", "trusted", "validated", "match"].freeze

    attr_reader :manifests

    # Provides high-level access to C2PA manifests contained in images,
    # if available.
    #
    # @param path_or_url [String] path/URL to image file
    # @param command [String] optional, the shell command to run for extraction (default: "c2patool")
    def initialize(path_or_url, command = "c2patool")
      @path_or_url = path_or_url
      @command = command
      @manifests = ImageWrangler::OPTS
      initialize_c2patool
      extract
    end

    # Returns true if C2PA manifests are present in the image.
    def present?
      @manifests.any?
    end

    # Returns true if the image is conforms to C2PA validation spec.
    def valid?
      return true unless present?

      @valid ||= validate
    end

    private

    def extract
      return @manifests unless @command_ok

      fh = ensure_local_file # File or Tempfile instance
      cmd = extraction_command(fh.path)

      begin
        result, _stdout, _stderr = Open3.capture3(cmd)
        @manifests = JSON.parse(result) unless result.empty?
      rescue => e
        raise ImageWrangler::Error.new(e)
      ensure
        fh.close
        fh.unlink if fh.is_a?(Tempfile)
      end

      @manifests
    end

    # TODO: implement fast access to remote files
    # instead of downloading.
    #
    # Down.download returns a Tempfile
    def ensure_local_file
      fh = ImageWrangler.url?(@path_or_url) ? Down.download(@path_or_url) : File.new(@path_or_url)
      raise ImageWrangler::Error.new("empty file") if fh.size.zero?
      fh
    rescue => e
      raise ImageWrangler::Error.new(e)
    end

    def extraction_command(filepath)
      [@command, "-d", filepath].shelljoin
    end

    def red(text)
      ImageWrangler.colorize(text, 31)
    end

    def initialize_c2patool
      @command_ok = false

      system("exec which #{@command} >/dev/null 2>&1")
      unless $?.success?
        raise ImageWrangler::Error.new("'#{@command}' command not found in PATH - please install")
      end

      @command_ok = true
    end

    def validate
      (validation_codes - VALIDATION_SUCCESS_STRINGS).empty?
    end

    def validation_codes
      validation_codes = @manifests.fetch("validation_status", []).map do |validation|
        validation.fetch("code", "").split(".").last&.downcase
      end

      validation_codes.compact.uniq
    end
  end
end
