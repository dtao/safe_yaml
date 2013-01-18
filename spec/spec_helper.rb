HERE = File.dirname(__FILE__)
ROOT = File.join(HERE, "..")

$LOAD_PATH << File.join(ROOT, "lib")
$LOAD_PATH << File.join(HERE, "support")

require "heredoc_unindent"
require "pry"

require File.join(HERE, "shared_specs")
