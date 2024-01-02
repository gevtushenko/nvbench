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

#pragma once

#include <nvbench/types.cuh>
#include <nvbench/detail/stopping_criterion.cuh>

#include <vector>

namespace nvbench::detail
{

class stdrel_criterion final : public stopping_criterion
{
  // parameters
  nvbench::float64_t m_min_time{0.5};
  nvbench::float64_t m_max_noise{0.005}; // 0.5% relative standard deviation

  // state
  nvbench::int64_t m_total_samples{};
  nvbench::float64_t m_total_cuda_time{};
  std::vector<nvbench::float64_t> m_cuda_times{};
  nvbench::detail::ring_buffer<nvbench::float64_t> m_noise_tracker{512};

public:
  virtual void initialize() override;
  virtual void add_measurement(nvbench::float64_t measurement) override;
  virtual bool is_finished() override;
};

} // namespace nvbench::detail
