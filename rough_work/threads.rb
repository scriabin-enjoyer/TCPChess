# frozen_string_literal: true

# rubocop:disable Lint

## EXCEPTIONS
# When joining 2 threads we must know how a thread can terminate:
#   - The happy path: the thread finishes executing its block and terminates
#   - The unhappy path: The thread raises an unhandled exception.
#
# In the unhappy path, a thread raises the exception and the thread terminates
# where the exception was raised – this does not affect other threads. HOWEVER,
# when this thread joins with another, the exception is re-raised in the
# joining thread.

## Thread#value
# the #value method is similar to #join but it returns the last returned value
# of the block/proc that was passed to the thread on initialization. This
# method has the same properties as #join regarding unhandled exceptions.

## Thread#status
# Every thread has a status, accessible from Thread#status
# It's most common for one thread to check the status of another, but a thread
# can check its own status using Thread.current.status
# STATUS VALUES:
# - run: returned when receiver thread is executing
# - sleep: Returned if this thread is sleeping or waiting on I/O
# - false: Returned when receiver thread is terminated normally
# - nil: Returned when receiver thread raised an exception
# - aborting: Returned when receiver thread is currently aborting

# Thread.stop and Thread#wakeup:
# Puts the receiver to sleep and tells the thread scheduler to schedule some
# other thread. The receiver will remain in the sleep state until Thread#wakeup
# is invoked on it. Once #wakeup is called the thread is handed back to the
# thread scheduler's control
unless :you_want_to_run_this_code
  thread = Thread.new do
    Thread.stop
    puts 'Hello there'
  end

  nil until thread.status == 'sleep'
  thread.wakeup
  thread.join
end

# Thread.pass
# This one is similar to Thread.stop, but instead of putting the current thread
# to sleep, it just asks the thread scheduler to schedule some other thread.
# HOWEVER, since the status of the current thread is not changed to 'sleep',
# the thread scheduler will not guarantee that it will actually schedule
# another thread (this is still left up to the OS and processor).

# This is a fun example I made to show that, indeed, the Thread.new call
# returns immediately and continues to execute the main thread until the thread
# scheduler decides to schedule other threads. This is what this program does:
# 1 sets variable names x and y to nil in the local binding table
# 2 spawns a new thread and immediately returns a thread object, assigning it
# to x
# 3 continues execution of the main thread, which goes on to spawn a new thread
# and return it immediately, assigning the thread object to y
# 4 At this point, the thread scheduler may decide to allow the main thread to
# continue holding the GIL, or it may decide to give the GIL to the x or y
# thread.
# 5 In the latter case (main still holds the GIL), the main thread is put to
# sleep for 1 second, signalling to the scheduler to hand control of the GIL to
# either the x or y thread
# 6 Reliably, the x thread gets a hold of the GIL and puts 'first'
# 7 Then either the y thread gets the GIL or the x thread continues execution,
# in which case it retrieves the current binding, and invokes
# local_variable_get(:y) on it, and the invokes .join on this object.
# Technically, this is an illegal operation because, textually, y has not been
# defined yet. Indeed, if we try to refer to y without accessing it through the
# current binding, this program raises an error. But because we did access it
# through binding, and because y has actually been assigned to a thread
# already, we can call join on y to join it with the x thread.
# 8 Then the y thread finishes, and the x thread gets the GIL, and finally it
# puts 'last'
# 9 At this point, there is likely a huge amount of the 1 second left that the
# main thread is blocking on, which runs out, and then it joins the (already
# terminated) x thread
unless :you_think_this_is_not_cool
  x = Thread.new { puts 'first'; binding.local_variable_get(:y).join; puts 'last' }
  y = Thread.new { puts 'second' }
  sleep 1
  [x, y].each(&:join)
end

# Okay so I tried this following code. My system gets up to ~32000 threads then
# my system freezes. open another terminal and use `pkill -9 ruby` to send
# SIGKILL to all processes that match "ruby"
unless :you_want_to_freeze_your_system
  1.upto(1_000_000) do |i|
    Thread.new { sleep }
    puts i
  end
  MY_MAX_THREADS = `cat /proc/sys/kernel/threads-max`
  puts "Your max thread count = #{MY_MAX_THREADS}"
  puts 'The above number is taken from /proc/sys/kernel/threads-max, which may or may not exist, so you may see some "does not exist" error if you dont have this file on your system or if its located somewhere else.'
end

# CONTEXT SWITCHING
# Theoretically, the maximum number of threads that can execute in parallel on
# a system is equal to the maximum number of cpu cores on the system. Thus, on
# CPU-bound operations, there is technically no performance benefit from using
# more threads than the maximum number of cores available. Additionally, there
# is some overhead generated when using many threads as the thread scheduler
# needs to allocate resources to manage all of the different threads.
#
# That said, there are times when it makes sense to use more threads than there
# are cores on the system.

# IO-BOUND
unless :you_want_to_annoy_httpbin
  require 'benchmark'
  require 'net/http'

  URL = 'https://httpbin.org/get'
  ITERATIONS = 30

  def fetch_url(thread_count)
    threads = []

    thread_count.times do
      threads << Thread.new do
        fetches_per_thread = ITERATIONS / thread_count

        fetches_per_thread.times do
          Net::HTTP.get URI(URL)
        end
      end
    end

    threads.each(&:join)
  end

  Benchmark.bm(20) do |bm|
    [1, 2, 3, 5, 6, 10, 15, 30].each do |t_count|
      bm.report("with #{t_count} threads") do
        fetch_url t_count
      end
    end
  end
end

# On my machine, the above shows an effectively linear increase in performance
# as the program spawns more threads. That is, the test with 30 threads yields
# the shortest execution time. For reference, my CPU has 16 virtual cores (2
# hardware threads per core with Simultaneous Multithreading (SMT)). In other
# situations, we might find that there is a better sweet-spot, possibly less
# possibly more, for the particular constraints of that situation.
# From the WWRT: "Finding the sweet spot is really important. Once you’ve done
# this a few times, you can probably start to make good guesses about how many
# threads to use, but the sweet spot will be different with different IO
# workloads, or different hardware."

# CPU-BOUND
# The flip side of IO-bound code is CPU-bound code, which is code whose
# execution is bound by the CPU capabilities of the machine on which the code
# runs. If some code is performing intensive calculations (especially of the
# mathematical kind), the performance of this code will be bound by the
# throughput of the CPU (i.e. ins/unit time). Apart from parallelization and
# better program design, the only way to improve the performance of such a
# program would be to scale the hardware vertically (i.e. buy better hardware)

unless :you_understand_the_gil
  require 'benchmark'
  require 'bigdecimal'
  require 'bigdecimal/math'

  DIGITS = 10_000
  ITERATIONS = 24

  def calc_pi(t_count)
    threads = []

    t_count.times do
      threads << Thread.new do
        iters_per_t = ITERATIONS / t_count
        iters_per_t.times { BigMath.PI(DIGITS) }
      end
    end

    threads.each(&:join)
  end

  Benchmark.bm do |bm|
    [1, 2, 3, 4, 6, 8, 12, 24].each do |t_count|
      bm.report("with #{t_count} threads: ") do
        calc_pi t_count
      end
    end
  end
end

# The above code actually has some interesting results on my system. With 1
# thread, the REAL/USER time was approximately 8 seconds (system time was
# 0.25s). With 3 to 24 threads, the user/real time was approximately  2.6
# seconds (and 0.25s sys time for 24 threads). This is possibly explainable by
# the fact that BigDecimal computations rely on computationally heavy code that
# actually releases the GIL (I think it's not just ruby code performing the
# computations, there are likely native C libraries that handle this stuff),
# with various other internal blocking points that the thread scheduler can use
# to switch threads — thus, we do see a speedup with more than 1 thread. Of
# course, this speedup is effectively constant and only occurs from the switch
# from 1 thread to >1 thread.

# With everything so far, I've had quite a difficult time manually inducing a
# race condition on shared data. I guess the ruby team has been hard at work
# (since ~2.0) improving the safety of Threads in the language, so surely this
# is a good thing.

unless :you_want_to_see_a_race_condition
  Order = Struct.new(:amount, :status) do
    def pending?
      status == 'pending'
    end

    def collect_payment(*loop_var)
      if !loop_var.empty?
        puts "Collecting payment... #{loop_var}"
      else
        puts "Collecting payment..."
      end
      self.status = 'paid'
    end
  end

  # Create a pending order for $100
  order = Order.new(100.00, 'pending')

  # Ask 5 threads to check the status, and collect
  # payment if it's 'pending'
  # Litter some puts statements throughout this loop to cause some more IO
  # intensive work. You should see different outputs depending on how much time
  # was already spent blocking on IO
  5.times.map do |i|
    Thread.new do
      # puts i
      if order.pending?
        # puts i
        order.collect_payment i
        # puts i
      end
      # puts i
    end
  end.each(&:join)
end

# MUTEXES AND PROTECTING DATA
# Mutex = Mutual Exclustion Use a mutex to lock the execution of a piece of
# code to a single thread. A mutex is an object that enforces the policy that
# only a single thread at a time may execute the piece of code that the mutex
# locks. In other words, a mutex prevents multiple threads from concurrently
# entering any critical section that is protected by that mutex (which, in our
# case, is the block that is passed to synchronize or sandwiched beterrn
# Mutex#lock and Mutex#unlock). Importantly, a mutex does not freeze or
# instruct the scheduler (the GIL) to allow only a single thread to execute for
# the duration of the critical section, rather, the scheduler is free to
# context switch to another thread at its discretion.

# If a thread encounters a critical section that is protected by a mutex:
#   - if another thread has already locked the mutex (possibly elsewhere), the
#   thread is blocked (put to sleep), and must wait for the thread that holds
#   the lock to release it in order to execute the critical section
#   - if the mutex is not locked, then the thread may proceed to execute the
#   critical section, locking the mutex

unless Mutex == Thread::Mutex
  shared_array = []
  mutex = Mutex.new

  10.times.map do
    Thread.new do
      1000.times do
        mutex.lock
        shared_array << nil
        mutex.unlock
      end
    end
  end.each(&:join)
  puts shared_array.size # This should always return 10000

  # Alternatively
  Thread.new do
    mutex.synchronize { shared_array << nil }
  end.join

  puts shared_array.size # This should always return 10001
end

# MUTEXES AND MEMORY VISIBILITY:
# Suppose 2 threads are running this code:
unless :asd
  status = mutex.synchronize { order.status }

  if status == 'paid'
    # send shipping notification
  end
end
# In this situation, we might think that there would be no race condition
# because all that thread would do here is read `order.status`, which is
# protected by a mutex lock, and assign it to its own `status` local variable,
# after which it reads it once again. But it may be the case that the value of
# `order.status` was recently changed from 'pending' to 'paid', and that the
# kernel cached this in, say, L2 before it was made visible in main memory.
# Then if another thread reads `order.status` from main memory, it may still
# read it as 'pending' even though the state of the program has technically
# changed. Thus the semantics here are still inconsistent.

# MUTEX PERFORMANCE AND COURSENESS
# Consider the following 2 examples. Which one do you think is more correct?
# NOTE: the xkcd url has been moved to some other identifier. Use chatGPT or
# something to get the correct URL, and fimplement some code to follow
# redirects until you get a 200
unless :example1
  require 'thread'
  require 'net/http'

  mutex = Mutex.new
  @results = []

  10.times.map do
    Thread.new do
      mutex.synchronize do
        response = Net::HTTP.get_response('dynamic.xkcd.com', '/random/comic/')
        random_comic_url = response['Location']

        @results << random_comic_url
      end
    end
  end.each(&:join)

  puts @results
end

unless :example2
  require 'thread'
  require 'net/http'

  mutex = Mutex.new
  threads = []
  results = []

  10.times do
    threads << Thread.new do
      response = Net::HTTP.get_response('dynamic.xkcd.com', '/random/comic/')
      random_comic_url = response['Location']

      mutex.synchronize do
        results << random_comic_url
      end
    end
  end

  threads.each(&:join)
  puts results
end

# The second one is more correct. In the first case the mutex squeezes each
# thread into bottleneck: the first thread that acquires the lock blocks all
# other threads trying to enter the critical section, then this firs thread
# completes and appends the url to the results array.
# IMPORTANT TAKEAWAY: put as little code in your critical sections as possible, just
# enough to ensure that your data won’t be modified by concurrent threads.

# THE DREADED DEALOCK
# A deadlock may occur when one thread is blocked waiting for some resource from
# another thread, while this other thread is itself blocked waiting for a
# resource. This situation becomes a deadlock when neither thread can move
# forward. The simplest example of this situation here is when we have 2
# threads, each holding their own mutex, and the threads then try to acquire
# the mutex held by the other thread.

unless :you_like_deadlocks
  m1 = Mutex.new
  m2 = Mutex.new

  # First thread acquires m1, now locked. Then it sleeps for a bit of time to
  # allow the second thread to acquire and lock m2, then it tries to acquire
  # m2 (which should be locked by the time this thread tries to acquire it)
  t1 = Thread.new do
    m1.synchronize do
      sleep 0.1
      m2.synchronize {}
    end

    puts 'I will likely never be printed'
  end

  # Second thread acquires m2 after t1 has already locked m1. Then it tries to
  # acquire m1, but m1 is locked, waiting for m2 to release, but m2 can only
  # release if m1 is released, which can only release if m2 is released...
  t2 = Thread.new do
    m2.synchronize do
      m1.synchronize {}
    end

    puts 'I too will likely never be printed'
  end

  [t1, t2].each(&:join)
end

# One way to ameliorate the above situation is using the `Mutex#try_lock`
# method, which is like `lock`, but instead will just return false if the mutex
# is already locked, and true otherwise:
unless :you_like_deadlocks
  m1 = Mutex.new
  m2 = Mutex.new

  t1 = Thread.new do
    m1.synchronize do
      sleep 0.1
      m2.synchronize {}
    end

    puts 't1 should print this now'
  end

  # Second thread acquires m2 after t1 has already locked m1. Then it tries to
  # acquire m1, but m1 is locked, waiting for m2 to release, but m2 can only
  # release if m1 is released, which can only release if m2 is released...
  t2 = Thread.new do
    m2.synchronize do
      locked = m1.try_lock {}
      m1.unlock if locked
    end

    puts 't2 should print this now'
  end

  [t1, t2].each(&:join)
end

# The above situation can still cause a phenomena called "livelocking", which
# is similar to a deadlock except the threads aren't blocked waiting for the
# locks to release, rather, the threads are stuck in some loop with eachother
# with neither of them able to progress. For instance, if Thread A acquires
# Mutex A, and Thread B Acquires Mutex B, then both `try_lock` the other mutex,
# both fail, both unlock their first mutex, then both re-acquire their first
# mutex, etc. etc. It's like when you are walking along a narrow path and
# encounter another person walking towards you, and you both step left and
# right simultaneously to avoid colliding, but you keep in sync and it's funny
# and awkward and slightly uncomfortable. I won't give an example of this
# because I just have to move on.
#
# BIG TAKEAWAY: A better solution is to define a mutex hierarchy. In other
# words, any time that two threads both need to acquire multiple mutexes, make
# sure they do it in the same order. This will avoid deadlock every time.
# Also, it seems that in my (contrived) example above, it just doesn't seem
# like a good idea to lock a mutex while executing code that is itself locked
# by another mutex. Perhaps this is not an uncommon thing to do, maybe I will
# encounter a situation in the future where I will need to do that. But, in the
# situation above, since both threads need to access both m1 and m2, the better
# solutions here is for both threads to first lock m1, then unlock m1, then
# lock m2, then unlock m2, in this order. That way, both threads can safely
# do the work it needs to do and release the lock when it's finished.

# SIGNALING THREADS WITH CONDITION VARIABLES
# Condition variables come from the pthreads (POSIX threads) API and correspond
# to the pthread_cond_t type and
# pthread_cond_{init|wait|signal|broadcast|destroy} functions.
# A ConditionVariable can be used to signal one or many threads when some event
# happens, or some state changes, whereas mutexes are a means of synchronizing
# access to resources. Thus, condvars provide an inter-thread control flow
# mechanicsm. For instance, if one thread should sleep until it receives some
# work to do, another thread can pass it some work, then signal it with a cond
# var to keep it from having to constantly check for new input.

# Here is the basic usage. Using condition variables, it is possible to suspend
# while in the middle of a critical section until a resource becomes available
unless :condvars_are_awesome
  mutex = Thread::Mutex.new
  resource = Thread::ConditionVariable.new

  a = Thread.new do
    # a locks the mutex
    mutex.synchronize do
      # a now needs the resource; ConditionVariable#wait unlocks the given
      # mutex and blocks, allowing another thread to acquire the mutex. The
      # mutex is reacquired by the current thread on wakeup. Wakeup may occur
      # when someone else calls resource.signal or resource.broadcast. Note
      # that, after waking, thread a must compete again to reacquire the mutex.
      resource.wait(mutex)
      # 'a' can now have the resource
      # do more work
    end
  end

  b = Thread.new do
    mutex.synchronize do
      # If a has already locked this mutex, then b cannot acquire it. But then
      # a calls #wait on the ConditionVariable, releasing the mutex, allowing
      # b to acquire it. b then processes this critical section, ultimately
      # releasing the mutex once this critical section has processed. This
      # #signal method wakes up the first thread in line waiting for this
      # condition variable to unlock
      resource.signal
    end
  end
end

# We will use an example to illustrate the API:
unless :cond_vars_are_good?
  require 'thread'
  require 'net/http'

  mutex    = Mutex.new
  condvar  = ConditionVariable.new
  results  = []

  Thread.new do
    10.times do
      response = Net::HTTP.get_response('dynamic.xkcd.com', '/random/comic/')
      random_comic_url = response['Location']

      mutex.synchronize do
        results << random_comic_url
        # Signal the condition variable to wakeup any threads that were waiting
        # on it
        condvar.signal
      end
    end
  end

  comics_received = 0

  until comics_received >= 10
    mutex.synchronize do
      # This is loop: first, it checks that
      condvar.wait(mutex) while results.empty?

      url = results.shift
      puts "You should check out #{url}"
    end

    comics_received += 1
  end
end

# In this example, the spawned thread makes 10 get requests for a random comic,
# and after each request, acquires a global lock in which it appends the comic
# url to a shared data object, then signals using the convar to wakeup any
# threads that were waiting on this mutex. The main thread on the other hand
# checks if the program has received 10 comics, and if not, attempts to acquire
# the lock, then after it does, checks to see if we've received a comic url (by
# accessing the shared data object) from the network,then dequeues the url for
# processing. If the shared data object was not updated by the time the main
# thread acquires the global lock, it would wait in that case for another
# thread to signal that the shared data was updated, then proceed with the rest
# of its critical section. Yikes.

# Here is some weird code that I wrote just to shminker around with condvars:
unless :fun_with_condvars
  m = Mutex.new
  cv = ConditionVariable.new
  ord = []

  t1 = Thread.new do
    puts 'entered 1, appending 1...'
    ord << 1
    puts "ord in 1: #{ord}"
    m.synchronize do
      puts 't1 acquired mutex'
      cv.wait m
      puts 't1 releasing'
    end
  end

  t2 = Thread.new do
    puts 'entered 2, appending 2...'
    ord << 2
    puts "ord in 2: #{ord}"
    m.synchronize do
      puts 't2 acquired mutex'
      cv.signal
      puts 't2 releasing'
    end
  end

  t3 = Thread.new do
    puts 'entered 3, appending 3'
    ord << 3
    puts "ord in 3: #{ord}"
    m.synchronize do
      puts 't3 acquired the mutex and will now release'
    end
  end

  [t1, t2, t3].each &:join
  p ord
end

# BROADCAST
# There’s one other part of this small API we didn’t cover: broadcast.
#
# There are two different methods that can signal threads:
# ConditionVariable#signal will wake up exactly one thread that’s waiting on this ConditionVariable.
# ConditionVariable#broadcast will wake up all threads currently waiting on this ConditionVariable.

# THREAD-SAFE DATA STRUCTURES
# A thread-safe queue is a queue that is safe to use by multiple threads
# without causing race conditions or corrupting the queue's internal state. We
# will implement a simple blocking queue. A blocking queue is a thread safe
# queue that may block a thread when it tries to execute some operation
# (push/pop) on it.

# Our requirements:
#   - Be able to push data onto the queue object while ensuring that no more than 1 thread can do this at the same time
#   - Be able to pop data off the queue ensuring that only 1 thread at a time can do this
#   - If the queue is empty, then #pop must wait for the queue to be non-empty to proceed

# Consider this following queue. It just wraps the native Array class.
unless :not_thread_safe
  # The problem with this code is that the underlying Array isn't thread-safe,
  # and this class doesn't use a Mutex; the modifications happening in the push
  # and pop methods will not protect the underlying Array from concurrent
  # modifications.
  class UnsafeQueue
    def initialize
      @queue = []
    end

    def push(val)
      @queue << val
    end

    def pop
      @queue.shift
    end
  end
end

# A Mutex will rectify this:
unless :queue_with_mutex
  # Here we make a mutex that is local to this object. There is no need for a
  # global mutex outside of instances of this Queue because different instances
  # of this class will provide their own thread-safety guarantees.
  # This allows us to do:
  #
  # Thread.new { blocking_queue << val }
  # Thread.new { blocking_queue.pop }
  #
  # without managing an external mutex ourselves.
  class QueueWithMutex
    def initialize
      @queue = []
      @mutex = Mutex.new
    end

    def push(val)
      @mutex.synchronize { @queue << val }
    end

    def pop
      @mutex.synchronize { @queue.shift }
    end
  end
end

# To guarantee the last requirement, we can use a condition variable:
if :blocking_queue
  class BlockingQueue
    def initialize
      @queue = []
      @mutex = Mutex.new
      @condvar = ConditionVariable.new
    end

    def push(val)
      @mutex.synchronize do
        @queue << val
        @condvar.signal
      end
    end

    def pop
      @mutex.synchronize do
        @condvar.wait(@mutex) while @queue.empty?
        @queue.shift
      end
    end
  end

  # Example: producer/consumer

  queue = BlockingQueue.new

  producer = Thread.new do
    10.times do
      # This thread can push to the queue only if no one else can modify it
      queue.push(Time.now.to_i)
      sleep 1
    end
  end

  consumers = []
  3.times do
    consumers << Thread.new do
      loop do
        # can pop from the queue only if nobody else has the mutex
        timestamp = queue.pop
        formatted_ts = timestamp.to_s.reverse.gsub(/(\d\d\d)/, '\1,').reverse
        puts "It's been #{formatted_ts} seconds since the epoch!"
      end
    end
  end

  producer.join
end

# In the above, suppose we didn't have the mutex guarantee. What could happen
# in that case?
#   - Two producers might << at the same time -> corrupting the array or lose
#   values.
#   - Two consumers might shift simultaneously ->  both might take the same
#   element or nil.
#   - A consumer could check #empty? right before a producer pushes ->
#   incorrect decisions or missed data.
#   - Internal state of the array could be observed mid-mutation ->
#   catastrophic.
#
# The mutex guarantess:
# At most 1 thread can touch the @queue at a time
# This prevents race conditions, lost updates, inconsistent reads, and internal
# Array corruption. The lock in the #push method prevents data corruption in
# the array and ensures every mutation is visible to waiting consumers. This
# method also signals the condition variable so that sleeping consumers that
# are waiting on @queue.empty? are woken up because there is now data to be
# consumed.
