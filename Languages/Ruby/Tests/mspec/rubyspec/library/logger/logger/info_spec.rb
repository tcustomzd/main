require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/common'

describe "Logger#info?" do
  before :each do
    @path = tmp("test_log.log")
    @log_file = File.open(@path, "w+")
    @logger = Logger.new(@path)
  end

  after :each do
    @logger.close
    @log_file.close unless @log_file.closed?
    File.unlink(@path) if File.exists?(@path)
  end

  it "returns true if severity level allows info messages" do
    @logger.level = Logger::INFO
    @logger.info?.should == true
  end
  
  it "returns false if severity level does not allow info messages" do
    @logger.level = Logger::FATAL
    @logger.info?.should == false
  end
end

describe "Logger#info" do
  before :each do
    @path = tmp("test_log.log")
    @log_file = File.open(@path, "w+")
    @logger = Logger.new(@path)
  end

  after :each do
    @logger.close
    @log_file.close unless @log_file.closed?
    File.unlink(@path) if File.exists?(@path)
  end

  it "logs a INFO message" do
    @logger.info("test")
    @log_file.rewind
    LoggerSpecs::strip_date(@log_file.readlines.first).should == "INFO -- : test\n"
  end

  it "accepts an application name with a block" do
    @logger.info("MyApp") { "Test message" }
    @log_file.rewind
    LoggerSpecs::strip_date(@log_file.readlines.first).should == "INFO -- MyApp: Test message\n"
  end

end
