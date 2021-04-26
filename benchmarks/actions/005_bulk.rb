# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require_relative '../lib/benchmarks'

Benchmarks.register \
  action: 'bulk',
  category: 'core',
  warmups: 10,
  repetitions: 1_000,
  operations:  10_000,
  setup: Proc.new { |runner|
    runner.runner_client.indices.delete(index: 'test-bench-bulk', ignore: 404)
    runner.runner_client.indices.create(index: 'test-bench-bulk', body: '{"settings": { "number_of_shards": 3, "refresh_interval":"5s"}}')
    runner.runner_client.cluster.health(wait_for_status: 'yellow')
  },
  measure: Proc.new { |n, runner|
    doc_path = Benchmarks.data_path.join('small/document.json')
    raise RuntimeError.new("Document at #{doc_path} not found") unless doc_path.exist?
    doc_body = doc_path.open.read.tr("\n", "").gsub(/\s{2,}/, "") + "\n"

    op_meta = %Q|{"index":{}}\n|.freeze
    op_body = ''

    1.upto(runner.operations).each do |i|
      op_body << op_meta
      op_body << doc_body
    end

    response = runner.runner_client.bulk index: 'test-bench-bulk', body: op_body
    raise RuntimeError.new("Incorrect response: #{response}") if response["errors"]
  }
