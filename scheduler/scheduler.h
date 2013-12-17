#pragma once
#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <set>
#include <thread>
#include <mutex>
#include <chrono>
#include <cstddef>

using namespace std;

namespace Reaspect {

	struct Task {
		string name;
		int dep_count;
		vector<string> resolve;

		Task(const string& name_, int dep_count_, const vector<string>& resolve_) : name(name_), dep_count(dep_count_), resolve(resolve_) {}

		virtual void go() = 0;
	};

	struct TaskCmp {
		bool operator()(Task *a, Task *b) const {
			if (a->resolve.size() != b->resolve.size()) return a->resolve.size() > b->resolve.size();
			return a->name < b->name;
		}
	};

/*
 *	Tasks List
 */
	class TasksList {
		map<string, Task*> tasks;
		set<Task*, TaskCmp> available_tasks;
		int tasks_remain;

		mutex tasks_mutex;
		mutex ava_mutex;

	public:
		TasksList() : tasks_remain(0) {}

		void registerTask(Task *task) {
			tasks_mutex.lock();
			tasks[task->name] = task;
			tasks_remain++;
			allowTask(task);

			tasks_mutex.unlock();			
		}

		void allowTask(Task *task) {
			if (task->dep_count == 0) {
				ava_mutex.lock();
				available_tasks.insert(task);
				tasks_remain--;
				ava_mutex.unlock();
			}
		}

		void solveTask(const string& name) {
			tasks_mutex.lock();
			for (const string& dep_name : tasks[name]->resolve) {
				tasks[dep_name]->dep_count--;
				allowTask(tasks[dep_name]);
			}
			tasks_mutex.unlock();
		}

		bool checkForExit() {
			ava_mutex.lock();
			bool res = (tasks_remain == 0 && available_tasks.empty());
			ava_mutex.unlock();
			return res;
		}

		Task* getTask() {
			Task *res = NULL;
			ava_mutex.lock();
			if (!available_tasks.empty()) {
				res = *available_tasks.begin();
				available_tasks.erase(available_tasks.begin());
			}
			ava_mutex.unlock();
			return res;
		}
	};

/*
 *	Worker
 */
	void Worker(TasksList& tasks) {
		while (!tasks.checkForExit()) {
			Task *task = tasks.getTask();
			if (task) {
                cerr << "calc " << task->name << endl;
				task->go();
				tasks.solveTask(task->name);
			} else {
                cerr << "wait..." << endl;
				this_thread::sleep_for(chrono::seconds(1));
			}
		}
	}

/*
 *	Scheduler
 */

	class Scheduler {
		TasksList tasks;
		vector<thread> workers;

		void workerJob() {

		}

	public:
		Scheduler() {}

		void registerTask(Task *task) {
			tasks.registerTask(task);
		}

		void start() {
			for (unsigned int i = 0; i < thread::hardware_concurrency(); ++i)
				workers.push_back(thread(Worker, ref(tasks)));
		}

		void wait() {
			for (thread& i : workers)
				i.join();
		}
	};

}
