/*
 *  Copyright 2020 NVIDIA Corporation
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

#include <nvbench/detail/transform_reduce.cuh>

#include <algorithm>
#include <functional>
#include <limits>
#include <numeric>
#include <vector>

namespace nvbench::detail
{

/**
 * Given a vector of samples and the precomputed sum of all samples in the
 * vector, return a measure of the noise in the samples.
 *
 * The noise metric is the relative unbiased sample standard deviation
 * expressed as a percentage: (std_dev / mean) * 100.
 */
inline nvbench::float64_t
compute_noise(const std::vector<nvbench::float64_t> &data,
              nvbench::float64_t sum)
{
  const auto num = static_cast<nvbench::float64_t>(data.size());
  if (num < 5) // don't bother with low sample sizes.
  {
    return std::numeric_limits<nvbench::float64_t>::infinity();
  }

  const auto mean = sum / num;
  const auto variance =
    nvbench::detail::transform_reduce(data.cbegin(),
                                      data.cend(),
                                      0.,
                                      std::plus<>{},
                                      [mean](nvbench::float64_t val) {
                                        val -= mean;
                                        val *= val;
                                        return val;
                                      }) /
    (num - 1);
  const auto abs_stdev = std::sqrt(variance);
  const auto rel_stdev = abs_stdev / mean;
  return rel_stdev * 100.;
}

// `data` must be sorted.
inline std::vector<nvbench::float64_t>
compute_percentiles(const std::vector<nvbench::float64_t> &data,
                    const std::vector<int> &percentiles)
{
  std::vector<nvbench::float64_t> results;
  results.reserve(percentiles.size());

  for (int p : percentiles)
  {
    p = std::clamp(p, 0, 100);

    const auto idx = (p == 100) ? (data.size() - 1) : (p * data.size() / 100);
    results.push_back(data[idx]);
  }

  return results;
}

// `data` must be sorted.
// Returns bins + 2 entries. The first and last entry are the number of samples
// below and above the histogram range.
inline std::vector<nvbench::int64_t>
compute_histogram(const std::vector<nvbench::float64_t> &data,
                  nvbench::float64_t min,
                  nvbench::float64_t stride,
                  std::size_t bins)
{
  std::vector<nvbench::int64_t> histo;
  histo.reserve(bins + 2);

  const auto first = data.cbegin();
  const auto last  = data.cend();
  auto iter        = first;

  for (std::size_t i = 0; i < bins + 1; ++i)
  {
    const auto level = min + stride * static_cast<nvbench::float64_t>(i);
    auto prev        = iter;
    iter             = std::lower_bound(iter, last, level);
    histo.push_back(static_cast<nvbench::int64_t>(std::distance(prev, iter)));
  }
  histo.push_back(static_cast<nvbench::int64_t>(std::distance(iter, last)));

  return histo;
}

} // namespace nvbench::detail
