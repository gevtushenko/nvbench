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
#include <nvbench/named_values.cuh>

#include <unordered_map>
#include <string>

namespace nvbench::detail
{

constexpr nvbench::float64_t compat_min_time() { return 0.5; }    // 0.5 seconds
constexpr nvbench::float64_t compat_max_noise() { return 0.005; } // 0.5% relative standard deviation

class criterion_params
{
  nvbench::named_values m_named_values;
public:

  void set_int64(std::string name, nvbench::int64_t value);
  void set_float64(std::string name, nvbench::float64_t value);

  [[nodiscard]] bool has_value(const std::string &name) const;
  [[nodiscard]] nvbench::int64_t get_int64(const std::string &name) const;
  [[nodiscard]] nvbench::float64_t get_float64(const std::string &name) const;
};

class stopping_criterion
{
public:
  virtual void initialize(const criterion_params &params) = 0;
  virtual void add_measurement(nvbench::float64_t measurement) = 0;
  virtual bool is_finished() = 0;
};

} // namespace nvbench::detail
