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

#include <nvbench/detail/criterion_registry.cuh>
#include <nvbench/detail/throw.cuh>

namespace nvbench::detail
{

criterion_registry::criterion_registry()
{
  this->register_criterion("stdrel", std::make_unique<stdrel_criterion>());
  this->register_criterion("entropy", std::make_unique<entropy_criterion>());
}

criterion_registry &criterion_registry::instance()
{
  static criterion_registry registry;
  return registry;
}

stopping_criterion* criterion_registry::get(const std::string& name)
{
  criterion_registry& registry = instance();

  auto iter = registry.m_map.find(name);
  if (iter == registry.m_map.end())
  {
    NVBENCH_THROW(std::runtime_error, "No stopping criterion named \"{}\".", name);
  }
  return iter->second.get();
}

bool criterion_registry::register_criterion(std::string name,
                                            std::unique_ptr<stopping_criterion> criterion)
{
  return m_map.emplace(std::move(name), std::move(criterion)).second;
}

} // namespace nvbench::detail
