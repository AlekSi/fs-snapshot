require 'helper'

class TestFsSnapshoter < Test::Unit::TestCase

	def all_children(root)
		res = []
		root.children.each do |child|
			res += [child]
			res += all_children(child) if child.directory?
		end
		res
	end

	def setup
		require 'tmpdir'
		data_dir      = Dir.tmpdir + "/fs-snap-#{$$}-data"
		snapshots_dir = Dir.tmpdir + "/fs-snap-#{$$}-snapshots"
		Dir.mkdir(data_dir)
		Dir.mkdir(snapshots_dir)
		@data_dir, @snapshots_dir = Pathname.new(data_dir), Pathname.new(snapshots_dir)
		@snapshoter = FsSnapshoter.new @data_dir, @snapshots_dir

		# create test dir structure
		File.new(@data_dir + 'file0', 'w+') << 'file0'

		Dir.mkdir @data_dir + 'dir1'
		File.new(@data_dir + 'dir1/file1', 'w+') << 'dir1/file1'

		Dir.mkdir @data_dir + 'dir2'
		File.new(@data_dir + 'dir2/file21', 'w+') << 'dir2/file21'
		File.new(@data_dir + 'dir2/file22', 'w+') << 'dir2/file22'

		Dir.mkdir @data_dir + 'dir2/dir21'
		File.new(@data_dir + 'dir2/dir21/file1', 'w+') << 'dir2/dir21/file1'
		File.new(@data_dir + 'dir2/dir21/file2', 'w+') << 'dir2/dir21/file2'
	end

	def teardown
		FileUtils.rm_rf @snapshots_dir
		FileUtils.rm_rf @data_dir
	end

	should "return passed parameters" do
		assert_contains [@data_dir, Pathname.new('/private' + @data_dir.to_s)], @snapshoter.data_dir
		assert_contains [@snapshots_dir, Pathname.new('/private' + @snapshots_dir.to_s)], @snapshoter.snapshots_dir
	end

	should "return empty snapshots list" do
		assert_equal [], @snapshoter.list
	end

	context "with one snapshot" do
		setup do
			@snapshoter.take 'snap1'
			assert_equal ['snap1'], @snapshoter.list
			assert_equal ['snap1'], @snapshoter.snapshots_dir.children(false).collect { |entry| entry.to_s }
		end

		should "delete snapshot" do
			@snapshoter.delete 'snap1'
			assert_equal [], @snapshoter.list
		end

		should "delete data and restore from snapshot" do
			children = all_children(@data_dir)
			FileUtils.rm_r @data_dir
			@snapshoter.restore 'snap1'
			assert_equal ['snap1'], @snapshoter.list
			assert_equal children, all_children(@data_dir)
		end

		should "raise exceptions" do
			assert_raise(RuntimeError) { @snapshoter.take('snap1') }
			assert_raise(RuntimeError) { @snapshoter.restore('no_such_snapshot') }
			assert_raise(RuntimeError) { @snapshoter.delete('no_such_snapshot') }
		end
	end

end
