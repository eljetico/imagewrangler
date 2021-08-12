# frozen_string_literal: true

class MiniExiftool
  attr_accessor :config_file

  def initialize filename_or_io=nil, opts={}
    @opts = @@opts.merge opts
    if @opts[:convert_encoding]
      warn 'Option :convert_encoding is not longer supported!'
      warn 'Please use the String#encod* methods.'
    end
    @config_file = @opts.fetch(:exiftool_config, nil)
    @filename = nil
    @io = nil
    @unmapped_tags = TagHash.new
    @values = TagHash.new
    @changed_values = TagHash.new
    @errors = TagHash.new
    load filename_or_io unless filename_or_io.nil?
  end

  # Returns an array of the tags (original tag names) of the read file.
  def tags
    @values.keys.map { |key| original_tag(key) }
  end

  # Returns an array of all changed tags.
  def changed_tags
    @changed_values.keys.map { |key| original_tag(key) }
  end

  # Save the changes to the file.
  def save
    if @io
      raise MiniExiftool::Error.new('No writing support when using an IO.')
    end
    return false if @changed_values.empty?
    @errors.clear
    temp_file = Tempfile.new('mini_exiftool')
    temp_file.close
    temp_filename = temp_file.path
    FileUtils.cp filename.encode(@@fs_enc), temp_filename
    all_ok = true
    @changed_values.each do |tag, val|
      original_tag = original_tag(tag)
      arr_val = val.kind_of?(Array) ? val : [val]
      arr_val.map! {|e| convert_before_save(e)}
      params = +"-q -P -overwrite_original "
      params << (arr_val.detect {|x| x.kind_of?(Numeric)} ? '-n ' : '')
      params << (@opts[:ignore_minor_errors] ? '-m ' : '')
      params << generate_encoding_params
      arr_val.each do |v|
        params << %Q(-#{original_tag}=#{escape(v)} )
      end
      result = run(cmd_gen(params, temp_filename))
      unless result
        all_ok = false
        @errors[tag] = @error_text.gsub(/Nothing to do.\n\z/, '').chomp
      end
    end
    if all_ok
      FileUtils.cp temp_filename, filename.encode(@@fs_enc)
      reload
    end
    temp_file.delete
    all_ok
  end

  # Returns a hash of the original loaded values of the MiniExiftool
  # instance.
  def to_hash
    result = {}
    @values.each do |k,v|
      result[original_tag(k)] = v
    end
    result
  end

  def original_tag(key)
    MiniExiftool.original_tag(key) || @unmapped_tags.fetch(key, key)
  end

  def set_values hash
    hash.each_pair do |tag,val|
      @values[tag] = convert_after_load(tag, val)

      # Handle tags not available from pstore
      unless MiniExiftool.original_tag(tag)
        @unmapped_tags[tag] = tag
      end
    end
    # Remove filename specific tags use attr_reader
    # MiniExiftool#filename instead
    # Cause: value of tag filename and attribute
    # filename have different content, the latter
    # holds the filename with full path (like the
    # sourcefile tag) and the former the basename
    # of the filename also there is no official
    # "original tag name" for sourcefile
    %w(directory filename sourcefile).each do |t|
      @values.delete(t)
    end
  end

  ############################################################################
  private
  ############################################################################

  def cmd_gen arg_str='', filename
    cmd = [
      @@cmd,
      with_config_file,
      arg_str.encode('UTF-8'),
      escape(filename.encode(@@fs_enc))
    ].compact.map {
      |s| s.force_encoding('UTF-8')
    }.join(' ')

    cmd
  end

  def with_config_file
    @with_config_file ||= begin
      return nil if @config_file.nil?

      return nil unless File.exist?(@config_file)

      ["-config", escape(@config_file.encode(@@fs_enc))].join(' ')
    end
  end
end
