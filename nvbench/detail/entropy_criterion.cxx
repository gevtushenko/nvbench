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

#include <nvbench/detail/entropy_criterion.cuh>
#include <nvbench/types.cuh>

#include <cmath>
#include <numeric>


namespace nvbench::detail
{


namespace 
{

template <class It>
std::pair<nvbench::float64_t, nvbench::float64_t> compute_linear_regression(It first, It last)
{
  const std::size_t n = static_cast<std::size_t>(std::distance(first, last));

  // Assuming x starts from 0
  const nvbench::float64_t mean_x = (static_cast<nvbench::float64_t>(n) - 1.0) / 2.0;
  const nvbench::float64_t mean_y = std::accumulate(first, last, 0.0) / static_cast<nvbench::float64_t>(n);

  // Calculate the numerator and denominator for the slope
  nvbench::float64_t numerator = 0.0;
  nvbench::float64_t denominator = 0.0;

  for (std::size_t i = 0; i < n; i++)
  {
    const nvbench::float64_t x_diff = static_cast<nvbench::float64_t>(i) - mean_x;
    numerator += x_diff * (first[i] - mean_y);
    denominator += x_diff * x_diff;
  }

  // Calculate the slope and intercept
  const nvbench::float64_t slope = numerator / denominator;
  const nvbench::float64_t intercept = mean_y - slope * mean_x;

  return std::make_pair(slope, intercept);
}


template <class It>
nvbench::float64_t compute_r2(It first, It last, nvbench::float64_t slope, nvbench::float64_t intercept)
{
  const std::size_t n = static_cast<std::size_t>(std::distance(first, last));

  const nvbench::float64_t mean_y = std::accumulate(first, last, 0.0) / static_cast<nvbench::float64_t>(n);

  nvbench::float64_t ss_tot = 0.0;
  nvbench::float64_t ss_res = 0.0;

  for (std::size_t i = 0; i < n; i++)
  {
    const nvbench::float64_t y = first[i];
    const nvbench::float64_t y_pred = slope * static_cast<nvbench::float64_t>(i) + intercept;

    ss_tot += (y - mean_y) * (y - mean_y);
    ss_res += (y - y_pred) * (y - y_pred);
  }

  if (ss_tot == 0.0)
  {
    return 1.0;
  }

  return 1.0 - ss_res / ss_tot;
}

}


void entropy_criterion::initialize(const criterion_params &params)
{
  m_total_samples = 0;
  m_total_cuda_time = 0.0;
  m_entropy_tracker.clear();
  m_freq_tracker.clear();

  if (params.has_value("max-angle"))
  {
    m_max_angle = params.get_float64("max-angle");
  }

  if (params.has_value("min-r2"))
  {
    m_min_r2 = params.get_float64("min-r2");
  }
}

nvbench::float64_t entropy_criterion::compute_entropy() 
{
  const std::size_t n = m_freq_tracker.size();
  if (n == 0)
  {
    return 0.0;
  }

  m_ps.resize(n);
  for (std::size_t i = 0; i < n; i++)
  {
    m_ps[i] = static_cast<nvbench::float64_t>(m_freq_tracker[i].second) /
              static_cast<nvbench::float64_t>(m_total_samples);
  }

  nvbench::float64_t entropy{};
  for (nvbench::float64_t p : m_ps)
  {
    entropy -= p * std::log2(p);
  }

  return entropy;
}

void entropy_criterion::add_measurement(nvbench::float64_t measurement)
{
  m_total_samples++;
  m_total_cuda_time += measurement;

  {
    auto key = measurement;
    constexpr bool bin_keys = true;

    if (bin_keys) 
    {
      const auto resolution_us = 0.5;
      const auto resulution_s = resolution_us / 1'000'000;
      const auto epsilon = resulution_s * 2;
      key = std::round(key / epsilon) * epsilon;
    }

    auto it = std::lower_bound(m_freq_tracker.begin(),
                               m_freq_tracker.end(),
                               std::make_pair(key, nvbench::int64_t{}));

    if (it != m_freq_tracker.end() && it->first == key)
    {
      it->second += 1;
    }
    else
    {
      m_freq_tracker.insert(it, std::make_pair(key, nvbench::int64_t{1}));
    }
  }

  m_entropy_tracker.push_back(compute_entropy());
}

bool entropy_criterion::is_finished()
{
  if (m_entropy_tracker.size() < 2)
  {
    return false;
  }

  const auto [slope, intercept] = compute_linear_regression(m_entropy_tracker.cbegin(), m_entropy_tracker.cend());
  const auto r2 = compute_r2(m_entropy_tracker.cbegin(), m_entropy_tracker.cend(), slope, intercept);

  if (slope > m_max_angle) 
  {
    return false;
  }

  if (r2 < m_min_r2)
  {
    return false;
  }

  return true;
}

const entropy_criterion::params_description &entropy_criterion::get_params() const
{
  static const params_description desc{
    {"max-angle", nvbench::named_values::type::float64},
    {"min-r2", nvbench::named_values::type::float64},
  };
  return desc;
}

} // namespace nvbench::detail
