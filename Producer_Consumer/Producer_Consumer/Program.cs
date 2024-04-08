using System;
using System.Collections.Generic;
using System.Threading;

namespace Producer_ConsumerCS
{
    public class Production
    {
        public static Random rand = new Random();
        public static string Work()
        {
            return $"item [{rand.Next(0,101)}]";
        }
    }

    public class Producer
    {
        private Semaphore full;
        private Semaphore empty;
        private Semaphore access;
        private Stack<string> storage;

        public Producer(Semaphore full, Semaphore empty, Semaphore access, Stack<string> storage)
        {
            this.full = full;
            this.empty = empty;
            this.access = access;
            this.storage = storage;
        }

        public void Produce(int producerIndex)
        {
            empty.WaitOne(); // Wait until there's space in the storage
            access.WaitOne(); // Acquire access to the storage

            storage.Push(Production.Work());
            Console.WriteLine($"Producer [{producerIndex}] produced {storage.First()}");

            access.Release(); // Release access to the storage
            full.Release(); // Signal that an item has been produced
        }
    }

    public class Consumer
    {
        private Semaphore full;
        private Semaphore empty;
        private Semaphore access;
        private Stack<string> storage;

        public Consumer(Semaphore full, Semaphore empty, Semaphore access, Stack<string> storage)
        {
            this.full = full;
            this.empty = empty;
            this.access = access;
            this.storage = storage;
        }

        public void Consume(int consumerIndex)
        {
            full.WaitOne(); // Wait until there's an item in the storage
            access.WaitOne(); // Acquire access to the storage

            string item = storage.Pop();
            //storage.Pop();
            Console.WriteLine($"Consumer [{consumerIndex}] take {item}");

            access.Release(); // Release access to the storage
            empty.Release(); // Signal that an item has been consumed
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            int producerAmount = 2;
            int consumerAmount = 2;
            Semaphore full = new Semaphore(0, 10); // Semaphore to track the number of full slots in the storage
            Semaphore empty = new Semaphore(10, 10); // Semaphore to track the number of empty slots in the storage
            Semaphore access = new Semaphore(1, 1); // Semaphore for controlling access to the storage
            Stack<string> storage = new Stack<string>(); // Shared storage for producer and consumer

            Producer[] producers = new Producer[producerAmount];
            Consumer[] consumers = new Consumer[consumerAmount];

            for (int i = 0; i < producerAmount; i++)
            {
                producers[i] = new Producer(full, empty, access, storage);
            }

            for (int i = 0; i < consumerAmount; i++)
            {
                consumers[i] = new Consumer(full, empty, access, storage);
            }

            Thread[] producerThreads = new Thread[producerAmount];
            Thread[] consumerThreads = new Thread[consumerAmount];

            for (int j = 0; j < producerAmount; j++)
            {
                int index = j; // Capture the value of j
                producerThreads[j] = new Thread(() =>
                {
                    for (int i = 0; i < 10; i++)
                    {
                        producers[index].Produce(index); // Use the captured index variable
                    }

                });
                producerThreads[j].Start();
            }

            for (int j = 0; j < consumerAmount; j++)
            {
                int index = j; // Capture the value of j
                consumerThreads[j] = new Thread(() =>
                {
                    for (int i = 0; i < 10; i++)
                    {
                        consumers[index].Consume(index); // Use the captured index variable
                    }
                });
                consumerThreads[j].Start();
            }

            foreach (Thread thread in producerThreads)
            {
                thread.Join();
            }

            foreach (Thread thread in consumerThreads)
            {
                thread.Join(); //
            }

            Console.WriteLine("All items produced and consumed.");
        }
    }
}
