function delete_node{K,V}(node::TreeNode{K,V}, key::K, tree::LLRBTree, treedebug::Array{LLRBTree,1})
  println("Entered node")
    if key<node.key
        if !isa(node.left, TreeLeaf)
            println("* Continue search if left is present")
            if (!node.left.isRed && !node.left.left.isRed)
              println("moved to the left")
              node=moveredleft(node)
              push!(treedebug, tree)
            end
            println("Remove from left recursion")
            node.left=delete_node(node.left, key, tree, treedebug)
            push!(treedebug, tree)
        else
            println("Left node was leaf so key cannot be here")
            throw(KeyError(key))
        end
    else
        if (node.left.isRed)
            println("Flip a 3 node or unbalance a 4 node")
            node=rotateright(node)
            push!(treedebug, tree)
        end
        if key==node.key && isa(node.right,TreeLeaf)
            println("Delete the node to the left")
            return TreeLeaf()
        end
        if !isa(node.right, TreeLeaf)
            println("* Continue search if right is present")
            if (!node.right.isRed && !node.right.left.isRed)
              println("moved to the right")
                node=moveredright(node)
                push!(treedebug, tree)
            end
            if key==node.key
                println("Find the smallest node on the right, swap, and remove it")
                min = minimum(node.right)
                node.key=min.key
                node.value=min.value
                node.right=deletemin(node.right)
            else
                node.right=delete_node(node.right,key, tree, treedebug)
                push!(treedebug, tree)
            end
        else
            println("Right node was leaf so key cannot be here")
            throw(KeyError(key))
        end
    end
    println("Maintain invariants and go one level up")
    return fixup(node)
end
function delete!{K}(tree::LLRBTree, key::K, treedebug::Array{LLRBTree,1})
  if(!tree.root.left.isRed && !tree.root.right.isRed )
    tree.root.isRed = true
  end

  tree.root = delete_node(tree.root, key, tree, treedebug)

  if(!isa(tree.root, TreeLeaf))
     tree.root.isRed = false
  end

  tree
end
