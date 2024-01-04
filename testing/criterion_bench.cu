/*
 *  Copyright 2023 NVIDIA Corporation
 *
 *  Licensed under the Apache License, Version 2.0 with the LLVM exception
 *  (the "License"); you may not use this file except in compliance with
 *  the License.
 *
 *  You may obtain a copy of the License at
 *
 *      http://llvm.org/foundation/relicensing/LICENSE.txt
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include <nvbench/stopping_criterion.cuh>
#include <nvbench/detail/entropy_criterion.cuh>
#include <nvbench/detail/stdrel_criterion.cuh>
#include <nvbench/types.cuh>

#include <chrono>
#include <random>
#include <iostream>

void bench_add_measurement() {
  nvbench::criterion_params params;
  nvbench::detail::entropy_criterion entropy;
  nvbench::detail::stdrel_criterion stdrel;

  stdrel.initialize(params);
  entropy.initialize(params);

  std::mt19937_64 gen(42);
  std::normal_distribution<nvbench::float64_t> dist(42.0, 1.0);

  for (std::size_t i = 0; i < 100'000; ++i) {
    nvbench::float64_t measurement = dist(gen);
    stdrel.add_measurement(measurement);
    entropy.add_measurement(measurement);

    if (i > 30) 
    {
      auto begin = std::chrono::high_resolution_clock::now();
      stdrel.is_finished();
      auto end = std::chrono::high_resolution_clock::now();
      const nvbench::float64_t stdrel_time = std::chrono::duration<nvbench::float64_t>(end - begin) .count();
      begin = std::chrono::high_resolution_clock::now();
      entropy.is_finished();
      end = std::chrono::high_resolution_clock::now();
      const nvbench::float64_t entropy_time = std::chrono::duration<nvbench::float64_t>(end - begin) .count();

      std::cout << i << "," << stdrel_time / entropy_time << std::endl;
    }
  }
}

int main() {
  bench_add_measurement();
}
