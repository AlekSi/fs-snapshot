require 'pathname'

class FsSnapshoter

	attr_reader :data_dir, :snapshots_dir

	def initialize(data_dir, snapshots_dir)
		@data_dir = Pathname.new(data_dir).expand_path.realpath
		@snapshots_dir = Pathname.new(snapshots_dir).expand_path.realpath
	end

	def snapshot_dir(name)
		Pathname.new(@snapshots_dir + name)
	end
	private :snapshot_dir

	# Returns array of existing snapshots.
	def list
		@snapshots_dir.children(false).collect { |entry| entry.to_s }
	end

	# Takes a snapshot.
	def take(name)
		raise "Snapshot already exists - '#{name}'!" if list.include? name
		dir = snapshot_dir(name)
		dir.mkdir
		FileUtils.cp_r @data_dir.to_s + '/.', dir
		return true
	end

	# Restores a snapshot.
	def restore(name)
		raise "No such snapshot - '#{name}'!" unless list.include? name
		FileUtils.rm_rf @data_dir
		FileUtils.cp_r snapshot_dir(name).to_s + '/.', @data_dir
		return true
	end

	# Deletes a snapshot.
	def delete(name)
		raise "No such snapshot - '#{name}'!" unless list.include? name
		FileUtils.rm_r snapshot_dir(name)
		return true
	end

end
