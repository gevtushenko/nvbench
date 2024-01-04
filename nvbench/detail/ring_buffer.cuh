/*
 *  Copyright 2021 NVIDIA Corporation
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

#include <nvbench/config.cuh>

#include <nvbench/detail/statistics.cuh>

#include <iterator>
#include <cassert>
#include <vector>

namespace nvbench::detail
{

/**
 * @brief A simple, dynamically sized ring buffer.
 */
template <typename T>
struct ring_buffer
{
private:
  using buffer_t = typename std::vector<T>;
  using diff_t   = typename buffer_t::difference_type;

  buffer_t m_buffer;
  std::size_t m_index{0};
  bool m_full{false};

  std::size_t get_front_index() const 
  {
    return m_full ? m_index : 0;
  }

public:
  struct iterator
  {
    using iterator_category = std::forward_iterator_tag;
    using value_type = T;
    using difference_type = std::ptrdiff_t;
    using pointer = const T*;
    using reference = const T&;

    iterator(std::size_t index, std::size_t capacity, pointer ptr)
        : m_index{index}
        , m_capacity{capacity}
        , m_ptr{ptr}
    {}

    iterator operator++()
    {
      ++m_index;
      return *this;
    }
    reference operator*() { return m_ptr[m_index % m_capacity]; }
    bool operator==(const iterator &other) const { return m_ptr == other.m_ptr && m_index == other.m_index; }
    bool operator!=(const iterator &other) const { return !(*this == other); }

  private:
    std::size_t m_index;
    std::size_t m_capacity;
    pointer m_ptr;
  };

  /**
   * Create a new ring buffer with the requested capacity.
   */
  explicit ring_buffer(std::size_t capacity)
      : m_buffer(capacity)
  {}

  /**
   * Iterators provide all values in the ring buffer in FIFO order.
   * @{
   */
  // clang-format off
  [[nodiscard]] iterator cbegin() const { return iterator{get_front_index(), capacity(), m_buffer.data()}; }
  [[nodiscard]] iterator cend() const { return iterator{get_front_index() + size(), capacity(), m_buffer.data()}; }
  // clang-format on
  /** @} */

  /**
   * The number of valid values in the ring buffer. Always <= capacity().
   */
  [[nodiscard]] std::size_t size() const { return m_full ? m_buffer.size() : m_index; }

  /**
   * The maximum size of the ring buffer.
   */
  [[nodiscard]] std::size_t capacity() const { return m_buffer.size(); }

  /**
   * @return True if the ring buffer is empty.
   */
  [[nodiscard]] bool empty() const { return m_index == 0 && !m_full; }

  /**
   * Remove all values from the buffer without modifying capacity.
   */
  void clear()
  {
    m_index = 0;
    m_full  = false;
  }

  /**
   * Add a new value to the ring buffer. If size() == capacity(), the oldest
   * element in the buffer is overwritten.
   */
  void push_back(T val)
  {
    assert(m_index < m_buffer.size());

    m_buffer[m_index] = val;

    m_index = (m_index + 1) % m_buffer.size();
    if (m_index == 0)
    { // buffer wrapped
      m_full = true;
    }
  }

  /**
   * Get the most recently added value.
   * @{
   */
  [[nodiscard]] auto back() const
  {
    assert(!this->empty());
    const auto back_index = m_index == 0 ? m_buffer.size() - 1 : m_index - 1;
    return m_buffer[back_index];
  }
  [[nodiscard]] auto back()
  {
    assert(!this->empty());
    const auto back_index = m_index == 0 ? m_buffer.size() - 1 : m_index - 1;
    return m_buffer[back_index];
  }
  /**@}*/
};

} // namespace nvbench::detail
