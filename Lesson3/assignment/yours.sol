/*作业请提交在这个目录下*/



第三题：

在讲Solidity的多重继承时遇到了C3 Linearization这个概念，查阅维基百科后，发现它是在面向对象的多重继承时遇到的问题，我不知道如何翻译，先翻译为C3线序化吧。

多重继承时会出现比较复杂的情况，在父类中出现相同的方法时，在子类中出现的调用语句需要知道明确地调用谁。因此有了这个线序化的算法，详性见 https://en.wikipedia.org/wiki/C3_linearization

主要的步骤在这样一段话中：

The merge of parents' linearizations and parents list is done by selecting the first head of the lists which does not appear in the tail (all elements of a list except the first) of any of the lists. Note, that a good head may appear as the first element in multiple lists at the same time, but it is forbidden to appear anywhere else. The selected element is removed from all the lists where it appears as a head and appended to the output list. The process of selecting and removing a good head to extend the output list is repeated until all remaining lists are exhausted. If at some point no good head can be selected, because the heads of all remaining lists appear in any one tail of the lists, then the merge is impossible to compute due to cyclic dependencies in the inheritance hierarchy and no linearization of the original class exists.

假设父类是P，子类是C，它们的线序号分别记为L(P)，L(C)，则有：

子类C的线序号L(C)，第一个元素是其本身，然后是对L(P)和所有父类的merge运算，描述起来非常非常拗口，看例子和表达式就明白了。

merge操作也挺有意思，从每个数组中找head元素，并且这个head不能出现在其它数组的尾部tail。

关于tail的定义是这样的，head是一个元素，剩下的部分都是tail。例如：head([A,B,C,D]) = A，而tail([A,B,C,D]) = [B,C,D]

对于如下的合约（类）的继承关系：

contract O
contract A is O
contract B is O
contract C is O
contract K1 is A, B
contract K2 is A, C
contract Z is K1, K2
我用graphviz画出来它的类图。

digraph G{
   edge[dir="back"];
   O -> A
   O -> B
   O -> C
   A -> K1
   B -> K1
   A -> K2
   C -> K2
   K1 -> Z
   K2 -> Z
}
类图是这样的：![](https://steemitimages.com/0x0/https://steemitimages.com/DQmeCHD1ed2yahJp5ScXG9Xuh2ZjKSArs6hvmi5hPDgoKAW/c3-linearization.png)


计算各个类的线序的详细步骤：

L(O) := [O]  
L(A) := [A] + merge(L(O), [O]) // A本身 + merge(L(父亲) + 父亲列表)
      = [A] + merge([O], [O])
      = [A, O]  
L(B) := [B, O]
L(C) := [C, O]
L(K1):= [K1] + merge(L(A), L(B), [A, B])
      = [K1] + merge([A, O], [B, O], [A, B])
      = [K1, A] + merge([O], [B, O], [B])
      = [K1, A, B] + merge([O], [O])
      = [K1, A, B, O] 
L(K2):= [K2, A, C, O] 
L(Z) := [Z] + merge(L(K1), L(K2), [K1, K2])
      = [Z] + merge([K1, A, B, O], [K2, A, C, O], [K1, K2] )
      = [Z, K1] + merge([A, B, O], [K2, A, C, O], [K2] )
      = [Z, K1, K2] + merge([A, B, O], [A, C, O] )
      = [Z, K1, K2, A] + merge([B, O], [C, O] )
      = [Z, K1, K2, A, B] + merge([O], [C, O] )
      = [Z, K1, K2, A, B, C] + merge([O], [O] )
      = [Z, K1, K2, A, B, C, O]
有了这个线序化之后，当Z中有一个函数时，如果在父类中也存在，则沿着这个列表的顺序去找，先找到哪个就执行哪个类里的方法。
