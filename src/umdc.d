module umdc;

import std.math;
import std.stdio;
import std.container.array;
import std.typecons;
import std.conv;
import core.stdc.string;
import std.datetime.stopwatch;
import std.parallelism;
import std.range;

import math;
import matrix;
import util;
import traits;
import graphics;
import render;



//in D static rectangular array is continious in memory
int[16][256] edgeTable = [
                                   [-2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 8, 3, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 8, 3, -1, 1, 2, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 0, 2, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [10, 2, 3, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 8, 11, 2, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 9, 0, -1, 2, 3, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [8, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 8, 4, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 7, 9, -2, -1, -1, 1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 8, 4, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 0, 3, 7, 4, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 10, 9, -1, 8, 7, 4, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 7, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [8, 4, 7, -1, 3, 11, 2, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 0, 1, -1, 8, 4, 7, -1, 2, 3, 11, -2, -1, -1, -1, -1],
                                   [1, 2, 4, 7, 9, 11, -2, -1, -1, -1, -1, -1-1, -1, -1, -1, -1],
                                   [3, 11, 10, 1, -1, 8, 7, 4, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 7, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 7, 8, -1, 0, 3, 11, 10, 9, -2, -1, -1, -1, -1, -1, -1],
                                   [4, 7, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 5, 4, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 5, 4, -1, 0, 8, 3, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 5, 4, 1, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 5, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 9, 5, 4, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 0, 8, -1, 1, 2, 10, -1, 4, 9, 5, -2, -1, -1, -1, -1],
                                   [0, 2, 4, 5, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 5, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 5, 4, -1, 2, 3, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 4, 5, -1, 0, 2, 11, 8, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 0, 4, 5, 1, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 5, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 10, 1, -1, 9, 4, 5, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 9, 5, -1, 0, 1, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 5, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 4, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 7, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 5, 3, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 8, 7, 5, 9, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 0, 3, 7, 5, 9, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 11, -1, 5, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 7, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 11, -1, 0, 1, 5, 7, 8, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 10, 1, -1, 8, 7, 5, 9, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 7, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 7, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 6, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -1, 10, 5, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 10, 5, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 3, 8, 9, 1, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -1, 1, 2, 6, 5, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 6, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 6, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 10, 6, 5, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 0, 8, 2, 11, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 0, 1, 9, -1, 10, 5, 6, -2, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 11, 2, 8, 9, 1, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 5, 6, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 6, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 6, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 6, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [8, 7, 4, -1, 5, 6, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 6, 10, -1, 0, 3, 4, 7, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 1, 9, 0, -1, 8, 7, 4, -2, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 7, 4, 9, 1, 3, -2, -1, -1, -1, -1, -1, -1],
                                   [8, 7, 4, -1, 1, 2, 6, 5, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 7, 4, -1, 1, 2, 6, 5, -2, -1, -1, -1, -1, -1, -1],
                                   [8, 7, 4, -1, 0, 9, 2, 5, 6, -2, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 5, 6, 7, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 5, 6, 10, -1, 8, 7, 4, -2, -1, -1, -1, -1],
                                   [10, 5, 6, -1, 0, 2, 11, 7, 4, -2, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 0, 1, 9, -1, 10, 5, 6, -1, 8, 7, 4, -2],
                                   [10, 5, 6, -1, 7, 4, 11, 2, 1, 9, -2, -1, -1, -1, -1, -1],
                                   [8, 7, 4, -1, 3, 11, 6, 5, 1, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 5, 6, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [8, 7, 4, -1, 6, 5, 9, 0, 11, 3, -2, -1, -1, -1, -1, -1],
                                   [4, 5, 6, 7, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 6, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -1, 9, 10, 6, 4, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 6, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 6, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 6, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -1, 1, 2, 4, 6, 9, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 6, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 2, 3, -1, 9, 4, 10, 6, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 11, 8, -1, 9, 4, 6, 10, -2, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 11, -1, 0, 1, 4, 6, 10, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 6, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 6, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 6, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 6, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 6, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [6, 7, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 6, 7, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 6, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 6, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 6, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 6, 7, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 6, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 6, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 10, 6, 9, 7, 8, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 6, 7, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [3, 11, 2, -1, 8, 7, 0, 1, 10, 6, -2, -1, -1, -1, -1, -1],
                                   [1, 2, 6, 7, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 6, 7, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 6, 7, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 6, 7, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [6, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 0, 3, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 0, 9, 1, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 1, 3, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 1, 2, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 1, 2, 10, -1, 0, 3, 8, -2, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 0, 9, 10, 2, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 2, 3, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 6, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 6, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 3, 2, 6, 7, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 6, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 6, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 6, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 6, 7, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [6, 7, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 6, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 6, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 8, 4, 11, 6, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 6, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 8, 4, 6, 11, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 0, 3, 11, 6, 4, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 9, 10, 2, -1, 8, 4, 11, 6, -2, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 6, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 6, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 2, 3, 8, 4, 6, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 6, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 6, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 6, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 6, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 6, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [6, 7, 11, -1, 4, 5, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [6, 7, 11, -1, 4, 5, 9, -1, 0, 3, 8, -2, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 1, 0, 5, 4, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 8, 3, 1, 5, 4, -2, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 4, 5, 9, -1, 1, 2, 10, -2, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 4, 5, 9, -1, 1, 2, 10, -1, 0, 3, 8, -2],
                                   [11, 7, 6, -1, 0, 2, 10, 5, 4, -2, -1, -1, -1, -1, -1, -1],
                                   [11, 7, 6, -1, 8, 3, 2, 10, 5, 4, -2, -1, -1, -1, -1, -1],
                                   [4, 5, 9, -1, 3, 2, 6, 7, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 5, 9, -1, 2, 0, 8, 7, 6, -2, -1, -1, -1, -1, -1, -1],
                                   [3, 2, 6, 7, -1, 0, 1, 5, 4, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 5, 6, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [9, 4, 5, -1, 1, 10, 6, 7, 3, -2, -1, -1, -1, -1, -1, -1],
                                   [9, 4, 5, -1, 6, 10, 1, 0, 8, 7, -2, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 5, 6, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 5, 6, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 6, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 6, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 6, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 5, 6, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 9, 5, 6, 11, 8, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -1, 9, 0, 3, 11, 6, 5, -2, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 6, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 6, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 6, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 6, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 5, 6, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 6, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 5, 6, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 6, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 6, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 6, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 10, 11, -1, 0, 3, 8, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 10, 11, -1, 0, 1, 9, -2, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 10, 11, -1, 3, 8, 9, 1, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 7, 11, -1, 0, 3, 8, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 7, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 7, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 5, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 5, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 7, 3, 2, 10, 5, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 5, 7, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 5, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 5, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 5, 7, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [5, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 5, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 5, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 8, 11, 10, 4, 5, -2, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 5, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 5, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 4, 5, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 5, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 5, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 5, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 5, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -1, 8, 3, 2, 10, 5, 4, -2, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 5, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 5, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 5, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 5, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 5, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 7, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -1, 10, 9, 4, 7, 11, -2, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 7, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 7, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 7, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 7, 9, 11, -1, 0, 3, 8, -2, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 7, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 7, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 4, 7, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 4, 7, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 4, 7, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 4, 7, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 4, 7, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 4, 7, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 4, 7, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [4, 7, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [8, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 9, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 8, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 10, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 8, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 9, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 8, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 11, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [2, 3, 8, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 2, 9, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 2, 3, 8, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 2, 10, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [1, 3, 8, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 1, 9, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [0, 3, 8, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                   [-2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]

                               ];

uint[256] vertexNumTable = [
                                   0, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1,
                                   1, 1, 2, 1, 2, 2, 2, 1, 2, 1, 3, 1, 2, 1, 2, 1,
                                   1, 2, 1, 1, 2, 3, 1, 1, 2, 2, 2, 1, 2, 2, 1, 1,
                                   1, 1, 1, 1, 2, 2, 1, 1, 2, 1, 2, 1, 2, 1, 1, 1,
                                   1, 2, 2, 2, 1, 2, 1, 1, 2, 2, 3, 2, 1, 1, 1, 1,
                                   2, 2, 3, 2, 2, 2, 2, 1, 3, 2, 4, 2, 2, 1, 2, 1,
                                   1, 2, 1, 1, 1, 2, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1,
                                   1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1,
                                   1, 2, 2, 2, 2, 3, 2, 2, 1, 1, 2, 1, 1, 1, 1, 1,
                                   1, 1, 2, 1, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1,
                                   2, 3, 2, 2, 3, 4, 2, 2, 2, 2, 2, 1, 2, 2, 1, 1,
                                   1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                   1, 2, 2, 2, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1,
                                   1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1,
                                   1, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                                   1, 2, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
                               ];

Vector3!float[8] cornerPoints = [
                                    vecS!([0.0f,0.0f,0.0f]),
                                    vecS!([1.0f,0.0f,0.0f]), //clockwise starting from zero y min
                                    vecS!([1.0f,0.0f,1.0f]),
                                    vecS!([0.0f,0.0f,1.0f]),


                                    vecS!([0.0f,1.0f,0.0f]),
                                    vecS!([1.0f,1.0f,0.0f]), //y max
                                    vecS!([1.0f,1.0f,1.0f]),
                                    vecS!([0.0f,1.0f,1.0f])
];


Vector2!uint[12] edgePairs = [
                                    vecS!([0u,1u]),
                                    vecS!([1u,2u]),
                                    vecS!([3u,2u]),
                                    vecS!([0u,3u]),

                                    vecS!([4u,5u]),
                                    vecS!([5u,6u]),
                                    vecS!([7u,6u]),
                                    vecS!([4u,7u]),

                                    vecS!([4u,0u]),
                                    vecS!([1u,5u]),
                                    vecS!([2u,6u]),
                                    vecS!([3u,7u]),
];


struct Cell{
    float[8] densities;
    Plane!float[size_t] hermiteData;
    uint config;
}

struct HermiteGrid{
    float a;
    size_t size; //number of cells along each axis
    Cell** cells;


    import std.conv : emplace;
    import core.stdc.stdlib : malloc, free;
    import core.memory : GC;


    this(float a, size_t size){
        auto ptrSize = (Cell*).sizeof;
        auto memSize = size * size * size * ptrSize;

        this.a = a;
        this.size = size;
        this.cells = cast(Cell**) malloc(memSize);

        memset(this.cells, 0, memSize);
    }

    ~this(){
        free(cells);
    }


    Cube!float cube(size_t x, size_t y, size_t z, Vector3!float offset){
        return Cube!float(offset + Vector3!float([(x + 0.5F)*a, (y + 0.5F) * a, (z + 0.5F) * a]), a / 2.0F);
    }
}

@Vector3!float sampleSurfaceIntersection(alias DenFn3)(const ref Line!(float,3) line, size_t n, ref DenFn3 f){
    auto ext = line.end - line.start;
    auto norm = ext.norm();
    auto dir = ext / norm;

    auto center = line.start + ext * 0.5F;
    auto curExt = norm * 0.25F;

    for(size_t i = 0; i < n; ++i){
        auto point1 = center - dir * curExt;
        auto point2 = center + dir * curExt;
        auto den1 = f(point1).abs();
        auto den2 = f(point2).abs();

        if(den1 <= den2){
            center = point1;
        }else{
            center = point2;
        }

        curExt *= 0.5F;
    }

    return center;

}

Vector3!float calculateNormal(alias DenFn3)(Vector3!float point, float eps, ref DenFn3 f){
    return Vector3!float([f(Vector3!float([point.x + eps, point.y, point.z])) - f(Vector3!float([point.x, point.y, point.z])),
                          f(Vector3!float([point.x, point.y + eps, point.z])) - f(Vector3!float([point.x, point.y, point.z])),
                          f(Vector3!float([point.x, point.y, point.z + eps])) - f(Vector3!float([point.x, point.y, point.z]))]);
}


bool isConstSign(float a, float b){
    return a > 0.0 ? b > 0.0 : b <= 0.0;
}

//outer array corresponds to each vertex to be placed inside the cell
//inner array binds edges according to the EMCT to that vertex
Array!(Array!uint) whichEdgesAreSigned(uint config){

    int[16] entry = edgeTable[config];
    if(entry[0] == -2)
        return Array!(Array!uint)();

    auto result = Array!(Array!uint)();
    auto curVertex = Array!uint();

    for(size_t i = 0; i < entry.length; ++i){
        auto k = entry[i];
        if(k >= 0){
            curVertex.insertBack(k);
        }else if(k == -2){
            result.insertBack(curVertex);
            return result;
        }else{
            result.insertBack(curVertex);
            curVertex = Array!uint();
        }
    }

    return result;
}

float calculateQEF(Vector3!float point, const ref Array!(Plane!float) planes){
    float qef = 0.0F;
    foreach(ref plane; planes[]){
        auto distSigned = plane.normal.dot(point - plane.point);
        qef += distSigned * distSigned;
    }

    return qef;
}

Vector3!float sampleQEFBrute(const ref Cube!float cube, size_t n, const ref Array!(Plane!float) planes){
    auto ext = Vector3!float([cube.extent, cube.extent, cube.extent]);
    auto min = cube.center - ext;

    auto bestQef = float.max;

    auto bestPoint = min;

    for(size_t i = 0; i < n; ++i){
        for(size_t j = 0; j < n; ++j){
            for(size_t k = 0; k < n; ++k){
                auto point = min + Vector3!float([ext.x * (2 * i + 1.0) / n, ext.y * (2 * j + 1.0) / n, ext.z * (2 * k + 1.0) / n]);
                auto qef = calculateQEF(point, planes);

                if(qef < bestQef){
                    bestQef = qef;
                    bestPoint = point;
                }
            }
        }
    }

    return bestPoint;
}

//5623ms
//vvv
//489 + 2303 ~~ 2792ms //200% speed increase

//TODO curently HermiteGrid is not used
void extract(alias DenFn3)(ref DenFn3 f, Vector3!float offset, float a, size_t size, size_t accuracy, Vector3!float color, RenderVertFragDef renderTriLight, RenderVertFragDef renderLines){



    //float[size + 1][size + 1][size + 1] densities; //TODO port this to stack(prob too big)
    auto densities = Array!float();
    densities.reserve((size + 1)*(size + 1)*(size + 1));
    densities.length = (size + 1)*(size + 1)*(size + 1);

    alias CellData = Tuple!(Vector3!float, "minimizer", Vector3!float, "normal"); //minimizer and normal

    auto features = Array!(CellData[12])(); //TODO does it auto initialize hashmap ?
    features.reserve(size * size * size);
    features.length = size * size * size; //make sure we can access any feature //TODO convert to static array
    //TODO switch to nogc hashmap or use arrays with O(1) access but more memory use as a tradeoff
    //TODO normals are duplicated !

    /*auto edges = Array!(CellData)();
    auto edgeCount = 3*(size + 1)*(size + 1)*size;
    features.reserve(edgeCount);
    features.length = edgeCount;*/


    pragma(inline,true)
    size_t indexDensity(size_t x, size_t y, size_t z){
        return z * (size + 1) * (size + 1) + y * (size + 1) + x;
    }

    pragma(inline,true)
    size_t indexFeature(size_t x, size_t y, size_t z){
        return z * size * size + y * size + x;
    }

    /*pragma(inline, true) //3 * (n+1)^2 * n
    size_t indexEdge(size_t x, size_t y, size_t z, size_t localEdgeId){//cell coordinates and local edge id

    }*/

    pragma(inline,true)
    Cube!float cube(size_t x, size_t y, size_t z){//cube bounds of a cell in the grid
        return Cube!float(offset + Vector3!float([(x + 0.5F)*a, (y + 0.5F) * a, (z + 0.5F) * a]), a / 2.0F);
    }

    pragma(inline,true)
    void loadDensity(size_t x, size_t y, size_t z){
        auto p = offset + vec3!float(x * a, y * a, z * a);
        densities[indexDensity(x,y,z)] = f(p);

    }

    pragma(inline,true)
    void loadCell(size_t x, size_t y, size_t z){
        auto cellMin = offset + Vector3!float([x * a, y * a, z * a]);
        auto bounds = cube(x,y,z);

        uint config = 0;

        if(densities[indexDensity(x,y,z)] < 0.0)
            config |= 1;
        if(densities[indexDensity(x+1,y,z)] < 0.0)
            config |= 2;
        if(densities[indexDensity(x+1,y,z+1)] < 0.0)
            config |= 4;
        if(densities[indexDensity(x,y,z+1)] < 0.0)
            config |= 8;

        if(densities[indexDensity(x,y+1,z)] < 0.0)
            config |= 16;
        if(densities[indexDensity(x+1,y+1,z)] < 0.0)
            config |= 32;
        if(densities[indexDensity(x+1,y+1,z+1)] < 0.0)
            config |= 64;
        if(densities[indexDensity(x,y+1,z+1)] < 0.0)
            config |= 128;


        if(config != 0 && config != 255){

            addCubeBounds(renderLines, bounds, Vector3!float([1,1,1])); //debug grid

            auto vertices = whichEdgesAreSigned(config);

            foreach(ref vertex; vertices){
                auto curPlanes = Array!(Plane!float)();
                curPlanes.reserve(4); //TODO find the most efficient number

                foreach(edgeId; vertex){
                    auto pair = edgePairs[edgeId];
                    auto v1 = cornerPoints[pair.x];
                    auto v2 = cornerPoints[pair.y];

                    auto edge = Line!(float,3)(cellMin + v1 * a, cellMin + v2 * a);
                    auto intersection = sampleSurfaceIntersection!(DenFn3)(edge, cast(uint)accuracy.log2() + 1, f);
                    auto normal = calculateNormal!(DenFn3)(intersection, a/8.0, f); //TODO test this `eps`

                    auto plane = Plane!float(intersection, normal);

                    curPlanes.insertBack(plane);


                    CellData cellData;
                    cellData.normal = normal;
                    features[indexFeature(x,y,z)][edgeId] = cellData;
                }

                //auto minimizer = bounds.center;
                auto minimizer = sampleQEFBrute(bounds, accuracy, curPlanes);

                addCubeBounds(renderLines, Cube!float(minimizer, a/10.0F), Vector3!float([1,1,0]));//debug minimizer

                foreach(edgeId; vertex){
                    features[indexFeature(x,y,z)][edgeId].minimizer = minimizer;
                }


            }
        }
    }

    pragma(inline,true)
    void extactSurface(size_t x, size_t y, size_t z){
        auto cell = features[indexFeature(x,y,z)]; //no need for reference store here as assoc array is a class


        auto d2 = densities[indexDensity(x+1,y,z+1)];
        auto d5 = densities[indexDensity(x+1,y+1,z)];
        auto d6 = densities[indexDensity(x+1,y+1,z+1)];
        auto d7 = densities[indexDensity(x,y+1,z+1)];

        uint edgeId = -1;

        if(!isConstSign(d5,d6)){ //edgeId = 5
            edgeId = 5;

            auto data = cell[edgeId];
            auto normal = data.normal;

            auto r = features[indexFeature(x+1,y,z)][7];
            auto ru = features[indexFeature(x+1,y+1,z)][3];
            auto u = features[indexFeature(x,y+1,z)][1];


            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, r.minimizer, ru.minimizer), color, normal);
            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, ru.minimizer, u.minimizer), color, normal);
        }


        if(!isConstSign(d7,d6)){ //edgeId = 6
            edgeId = 6;

            auto data = cell[edgeId];
            auto normal = data.normal;

            auto f = features[indexFeature(x,y,z+1)][4];
            auto fu = features[indexFeature(x,y+1,z+1)][0];
            auto u = features[indexFeature(x,y+1,z)][2];

            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, f.minimizer, fu.minimizer), color, normal);
            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, fu.minimizer, u.minimizer), color, normal);
        }

        if(!isConstSign(d2,d6)){ //edgeId = 10
            edgeId = 10;

            auto data = cell[edgeId];
            auto normal = data.normal;

            auto r = features[indexFeature(x+1,y,z)][11];
            auto rf = features[indexFeature(x+1,y,z+1)][8];
            auto f = features[indexFeature(x,y,z+1)][9];

            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, rf.minimizer, r.minimizer), color, normal);
            addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, f.minimizer, rf.minimizer), color, normal);
        }

        //another variant used with assoc array
        /*foreach(ref edgeIdAndMinimizer; cell.byKeyValue){
            auto edgeId = edgeIdAndMinimizer.key;
            auto data = edgeIdAndMinimizer.value;

            auto normal = data.normal;

            if(edgeId == 5){
                auto r = features[indexFeature(x+1,y,z)][7];
                auto ru = features[indexFeature(x+1,y+1,z)][3];
                auto u = features[indexFeature(x,y+1,z)][1];


                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, r.minimizer, ru.minimizer), color, normal);
                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, ru.minimizer, u.minimizer), color, normal);
            }else if(edgeId == 6){
                auto f = features[indexFeature(x,y,z+1)][4];
                auto fu = features[indexFeature(x,y+1,z+1)][0];
                auto u = features[indexFeature(x,y+1,z)][2];

                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, f.minimizer, fu.minimizer), color, normal);
                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, fu.minimizer, u.minimizer), color, normal);
            }else if(edgeId == 10){
                auto r = features[indexFeature(x+1,y,z)][11];
                auto rf = features[indexFeature(x+1,y,z+1)][8];
                auto f = features[indexFeature(x,y,z+1)][9];

                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, rf.minimizer, r.minimizer), color, normal);
                addTriangleColorNormal(renderTriLight, Triangle!(float,3)(data.minimizer, f.minimizer, rf.minimizer), color, normal);

            }
        }*/
    }

    StopWatch watch;


    watch.start();

    foreach(i; parallel(iota(0, size * size * size ))){
        auto z = i / (size+1) / (size+1);
        auto y = i / (size+1) % (size+1);
        auto x = i % (size+1);

        loadDensity(x,y,z);
    }

    watch.stop();

    ulong ms;
    watch.peek().split!"msecs"(ms);

    writeln("loading of densities took " ~ to!string(ms) ~ " ms");
    stdout.flush();

    watch.reset();
    watch.start();

    foreach(z; 0..size){
        foreach(y; 0..size){
            foreach(x; 0..size){
                loadCell(x,y,z);
            }
        }
    }

    /*foreach(i; parallel(iota(0, (size-1) * (size-1) * (size-1) + 1))){
        auto z = i / size / size;
        auto y = i / size % size;
        auto x = i % size;

        loadCell(x,y,z);
    }*/

    watch.stop();

    watch.peek().split!"msecs"(ms);

    writeln("loading of cells took " ~ to!string(ms) ~ " ms");
    stdout.flush();

    watch.reset();
    watch.start();

    foreach(z; 0..size-1){
        foreach(y; 0..size-1){
            foreach(x; 0..size-1){
                extactSurface(x,y,z);
            }
        }
    }

   /* foreach(i; parallel(iota(0, (size-2) * (size-2) * (size-2) + 1))){
        auto z = i / (size-1) / (size-1);
        auto y = (i / (size-1)) % (size-1);
        auto x = i % (size-1);

        extactSurface(x,y,z);
    }*/

    watch.stop();


    watch.peek().split!"msecs"(ms);
    writeln("isosurface extraction took " ~ to!string(ms) ~ " ms");
    stdout.flush();

}