#The LLRBTree data structure, that allows us to acces keys in log2 time.
#Translated from code by Robert Sedgewick
module LLRBTrees

  import Base: haskey, getindex, setindex!, delete!, minimum, push!

  export TreePart, TreeLeaf, TreeNode, LLRBTree, getnodefrom_key, setdebug, getmaxdepth, orderedpairs

  # We declare an abstract type, that contains the nodes and the leaves of the tree
  abstract TreePart

  type TreeNode{K,V} <: TreePart
      key::  K
      value:: V
      isRed::Bool
      left:: TreePart
      right:: TreePart
  end
  # Nodes are always red so no method that explicitly assings the color is neccessary
  TreeNode{K,V}(key::K,value::V,left::TreePart,right::TreePart) = TreeNode(key,value,true,left,right)
  TreeNode{K,V}(key::K,value::V) = TreeNode(key, value, true, TreeLeaf(), TreeLeaf())

  type TreeLeaf <: TreePart
      isRed::Bool
      # Leaves are always black
      TreeLeaf()=new(false)
  end

  # To be able to have different instances of LLRB trees, we create a tree type
  # that characterizes a tree by its root
  type LLRBTree
      root:: TreePart

      LLRBTree(node::TreePart) = (tree = new(); tree.root=node; tree.root.isRed=false; tree)
  end
  LLRBTree() = LLRBTree(TreeLeaf())
  LLRBTree(key, value) = (tree=LLRBTree(TreeNode(key,value)))

  # The function that returns the node that corresponds to a certain key, below a root-node
  # it returns a TreeLeaf when the root node is empty
  function getnodefrom_key(part::TreePart, key)
      # Return leaf if node is leaf
      if isa(part,TreeLeaf)
          return part

      # Check if root key is of the same type as given key
      elseif !isa(part.key,typeof(key))
          throw(ArgumenError("The type of the searched key must have the same type as the key of the root node"))

      # The recursive search for the key
      elseif part.key == key
          return part
      elseif key < part.key
          getnodefrom_key(part.left, key)
      else
          getnodefrom_key(part.right, key)
      end
  end
  getnodefrom_key(tree::LLRBTree, key) = getnodefrom_key(tree.root, key)

  haskey(tree::LLRBTree, key) = isa(getnodefrom_key(tree.root, key), TreeLeaf) ? false : true
  haskey(node::TreeNode, key) = isa(getnodefrom_key(node, key), TreeLeaf) ? false : true

  # A getindex only that the indexes are keys and we get the value of the first node with the given key
  function getindex(tree::LLRBTree, key)
      part::TreePart = getnodefrom_key(tree,key)
      # Throw a KeyException if the key is node.left present
      if isa(part, TreeLeaf)
          throw(KeyException(key))
      else
          return part.value
      end
  end

  function setindex!(tree::LLRBTree, value, key)
      part::TreePart = getnodefrom_key(tree,key)
      # Throw a KeyException if the key is not present
      if isa(part, TreeLeaf)
          throw(KeyException(key))
      else
          part.value=value
      end
  end

  #         |                                                             |
  #       node                              -> rotateleft ->             son
  #       /   \                                                         /  \
  #           son                                                      node
  #          /   \                                                    /  \
  function rotateleft(node::TreeNode)
      son=node.right

      if isa(son, TreeLeaf)
          error("The right part of the given node must be a node")
      end

      node.right=son.left
      son.left=node
      son.isRed=node.isRed
      node.isRed=true
      return son
  end

  #         |                                                              |
  #        node                              -> rotateright ->            son
  #       /   \                                                          /  \
  #     son                                                               node
  #    /   \                                                              /  \
  function rotateright(node::TreeNode)
      son=node.left

      if isa(son, TreeLeaf)
          error("The left part of the given node must be a node")
      end

      node.left=son.right
      son.right=node
      son.isRed=node.isRed
      node.isRed=true
      return son
  end

  function flipcolor!(node::TreeNode)

      node.isRed = !node.isRed
      node.left.isRed = !node.left.isRed
      node.right.isRed = !node.right.isRed
  end

  # Adds the specified key/value pair below the specified root node.
  # Shouldn't be exported because the tree root would not be updated
  function add_node{K,V}(node::TreePart, key::K, value::V)

      if isa(node, TreeLeaf)
          # Add the node only when a leaf is found
           #("node added")
          return TreeNode(key, value)
      end

      if node.key < key
          node.right = add_node(node.right, key, value)
      elseif node.key > key
          node.left = add_node(node.left, key, value)
      else
          node.value = value
          #return node      #If we uncomment this, there won't be an unneccesary
                            # rotation in the last subtrees, but the conversion to
                            # 2-3 trees won't be as easy
      end

      if node.right.isRed
           #("Rotate left to prevent red node on right")
          node=rotateleft(node)
      end
      if node.left.isRed && node.left.left.isRed
           #("Rotate right to prevent consecutive red nodes")
          node=rotateright(node)
      end
      if node.left.isRed && node.right.isRed
           #("Split node with two red children")
          flipcolor!(node)
           #(node)
      end

      return node
  end
  # For trees and nodes as parameters, different name so the other one doesn't get used
  push!{K,V}(tree::LLRBTree, key::K, value::V) = (tree.root = add_node(tree.root, key, value); tree.root.isRed=false; tree)
  push!{K,V}(tree::LLRBTree, node::TreeNode{K,V}) = (tree.root = add_node(tree.root, node.key, node.value); tree.root.isRed=false; tree)

  # Move the red node left
  function moveredleft{K,V}(node::TreeNode{K,V})
      flipcolor!(node)
      if (node.right.left.isRed)
          node.right = rotateright(node.right)
          node = rotateleft(node)
          #flipcolor!(node)

          #Avoid creating right-leaning nodes
          # if (node.right.right.isRed)
          #     node.right = rotateleft(node.right)
          # end
      end
      return node
  end

  # Move the red node right
  function moveredright{K,V}(node::TreeNode{K,V})
      flipcolor!(node)
      if (node.left.left.isRed)
          node= rotateright(node)
          #flipcolor!(node)
      end
      return node
  end

  # Gets the minimum below a certain node
  function minimum{K,V}(node::TreeNode{K,V})
      while !isa(node.left,TreeLeaf)
          node=node.left
      end
      return node
  end
  minimum(tree::LLRBTree) = minimum(tree.root)

  # Maintains invariants by adjusting the specified nodes children.
  # returns new root node
  function fixup{K,V}(node::TreeNode{K,V})
      if (node.right.isRed)
          node=rotateleft(node)
      end
      if (!isa(node.left,TreeLeaf) && node.right.isRed && !node.left.isRed)
          node=rotateleft(node)
      end
      if (!isa(node.left,TreeLeaf) && node.left.isRed && node.left.left.isRed)
          node=rotateright(node)
      end
      if (node.left.isRed && node.right.isRed)
          flipcolor!(node)
      end
      return node
  end

  function deletemin{K,V}(node::TreeNode{K,V})
      if isa(node.left, TreeLeaf)
          return TreeLeaf()
      end
      if !node.left.isRed && !node.left.left.isRed
          node=moveredleft(node)
      end
      # Recursively delete
      node.left=deletemin(node.left)
      fixup(node)
  end


  function delete_node{K,V}(node::TreeNode{K,V}, key::K)
      if key<node.key
          if !isa(node.left, TreeLeaf)
              if (!node.left.isRed && !node.left.left.isRed)
                node=moveredleft(node)
              end
              node.left=delete_node(node.left, key)
          else
              Base.warn_once("Key not found:", key)
              return fixup(node)
          end
      else
          if (node.left.isRed)
              #("Flip a 3 node or unbalance a 4 node")
              node=rotateright(node)
         end

          if (key==node.key && isa(node.right,TreeLeaf))
              return TreeLeaf()
          end
          if !isa(node.right, TreeLeaf)
              if (!node.right.isRed && !node.right.left.isRed)
                  node=moveredright(node)
              end
              if key==node.key
                  #("Find the smallest node on the right, swap, and remove it")
                  min = minimum(node.right)
                  node.key=min.key
                  node.value=min.value
                  node.right=deletemin(node.right)
              else
                  node.right=delete_node(node.right,key)
              end
          else
              Base.warn_once("Key not found:", key)
              return fixup(node)
          end
      end
      return fixup(node)
  end
  function delete!{K}(tree::LLRBTree, key::K)
    if(!tree.root.left.isRed && !tree.root.right.isRed )
      #We paint the node red so that later when we flip colors to split a 4 node
      # it also is converted to black
      tree.root.isRed = true
    end

    tree.root = delete_node(tree.root, key)

    if(!isa(tree.root, TreeLeaf))
       tree.root.isRed = false
    end

    tree
  end

  function getmaxdepth{K,V}(node::TreeNode{K,V}, depth=1)
      #We do a caching up of the number of recursions with the use of parameters and returns
      depthleft=depthright=depth
      if !isa(node.left, TreeLeaf)
          #("left in at $depth")
          depthleft = getmaxdepth(node.left, depth+1)
      end
      if !isa(node.right, TreeLeaf)
          #("right in at $depth")
          depthright = getmaxdepth(node.right, depth+1)
      end
      #("out at $depth")
      #([depthleft,depthright])
      return maximum([depthleft,depthright])
  end
  getmaxdepth(tree::LLRBTree) = getmaxdepth(tree.root)

  #Return an ordered list with recursion
  function inorder(node::TreePart, list=Any[])
      if !isa(node, TreeLeaf)

          if !isa(node.left, TreeLeaf)
              #("Go down to the left first")
              list = inorder(node.left, list)[2]
          end

          #("Push to the list when leftmost")
          push!(list, [node.key, node.value])

          if !isa(node.right, TreeLeaf)
              #("Go right if no left")
              list = inorder(node.right, list)[2]
          end
      end
      #("Go up;  ",node,";  ",list)
      return node, list
  end
  orderedpairs(tree::LLRBTree) = inorder(tree.root)[2]

  module LLRBVisualize

      using LLRBTrees
      using Compose
      using Colors

      export iterate_undernode, drawASCII, drawtree

      #Columns in which the nodes are to be drawn
      abstract Column

      #For the left and rightmost columns
      type ColumnEmpty <: Column
      end

      #The idea is that one can insert a column between two columns making space for any new node
      #That is why we need a link to both sides
      type ColumnFull <: Column
          left:: Column
          right:: Column
          parent::Column
          node:: TreePart
          height :: Int64

          ColumnFull(node :: TreePart) = new(ColumnEmpty(), ColumnEmpty(), ColumnEmpty(), node, 1)
          ColumnFull(cleft:: Column, cright::Column, cparent::Column, node::TreePart, height :: Int64) = new(cleft, cright, cparent, node, height)
      end
      #Get the place from left to right of the given column
      function columnindex(col::ColumnFull)
          i=0
          while !isa(col, ColumnEmpty)
              i+=1
              col=col.left
          end
          i
      end

      function buildcolumns(col::ColumnFull)

          leftnode = col.node.left
          rightnode = col.node.right

          #First create the columns recursively to the left until there are no more nodes
          if isa(leftnode, TreeNode)
              #Creation of the new column
              colleft = ColumnFull(col.left, col, col, leftnode, col.height+1)

              #Correcting links
              col.left = ColumnEmpty()
              if isa(colleft.left, ColumnFull)
                  colleft.left.right = colleft
              end
              col.left = colleft

              buildcolumns(colleft)
          end

          if isa(rightnode, TreeNode)
              #Creation of the new column
              colright = ColumnFull(col, col.right, col, rightnode, col.height+1)

              #Correcting links
              col.right = ColumnEmpty()
              if isa(colright.right, ColumnFull)
                  colright.right.left = colright
              end
              col.right = colright

              buildcolumns(colright)
          end
          return col
      end
      buildcolumns(tree::LLRBTree) = buildcolumns( ColumnFull(tree.root) )

      function spacesstring(length::Int64, space="    " )
         string=""
          for i in 1:length
              string = "$string$space"
          end
          string
      end

      #The column given must be the one that contains the root node
      function drawASCII(col::ColumnFull)

          #For calculating indent
          maxheight=getmaxdepth(col.node)

          #Get the leftmost column
          while !isa(col.left, ColumnEmpty)
             col = col.left
          end

          #Print from left to right
          while true
              length = maxheight - col.height
              println(spacesstring(length), col.node.key)
              col = col.right
              isa(col, ColumnEmpty) && break
          end
      end
      drawASCII(tree::LLRBTree) =( col = buildcolumns(tree); drawASCII(col) )

      #Returns an array that has the coordinates in which the nodes are to be drawn,
      #the index of the parents for drawing the connections and the value to be printed inside
      #The column given must be the one that contains the root node
      function getcoords(col::ColumnFull)

          #Get the y dimension
          maxheight=getmaxdepth(col.node)

          #We'll start writing from the left
          while !isa(col.left, ColumnEmpty)
             col = col.left
          end

          #Get the x dimension
          length=1
          col2=col
          while !isa(col2.right, ColumnEmpty)
             col2 = col2.right
              length+=1
          end

          #Define the cell dimensions in relative coordinates
          width=1/length
          height=1/maxheight
          coords = Any[]

          #Write to the array from left to right
          x = -width
          while true
              y = -height/2 + col.height*height
              x += width
              parentid = isa(col.parent, ColumnFull) ? columnindex(col.parent): 0
              push!( coords, Any[ x, y, parentid, col.node.value, col.node.isRed ] )

              col = col.right
              isa(col, ColumnEmpty) && break
          end

          coords
      end

      #Vector graphic representation with Compose.jl
      function drawtree(coords)
          circles = Any[]
          lines = Any[]
          width = length(coords)
          #Make a list of all the circles to be drawn
          for i in 1:width

              x = coords[i][1]
              y = coords[i][2]

              #Build the line from children to parent if present
              parent = coords[i][3]
              if parent!=0
                  xp= coords[parent][1]
                  yp= coords[parent][2]

                  ad = 0.5/width

                  treeline = compose(context(), line([(x+ad, y+ad), (xp+ad, yp+ad)]), stroke(colorant"black") )
                  push!(lines, treeline)
              end

              #Build the circle
              coloring = coords[i][5] ? colorant"red" : colorant"black"
              value = coords[i][4]
              circle_ = treecircle(x, y, 1/width, string(value), coloring )
              push!(circles, circle_)
          end

          compose(context(), circles..., lines..., stroke(colorant"white"), fontsize(1/width*50), linewidth(0.1mm))
      end
      drawtree(col::ColumnFull) = drawtree(getcoords(col))
      drawtree(tree::LLRBTree) = drawtree(buildcolumns(tree))

      function treecircle(x::Float64, y::Float64, side::Float64, value::String, coloring )
          compose(context(x, y, side, side), circle(), fill(coloring), (context(0,0), text(0.2,0.65,value), fill(colorant"white")))
      end

      #Stange triangle visualization
      function iterate_undernode(node::TreePart, isLeft::Bool=true)
          if isa(node,TreeLeaf)
              compose(context(), polygon([(1,1), (0,1), (1/2, 0)]))
              #=if isLeft
                                      compose(context(), polygon([(1,0.5), (0,0)]))
                                  else
                                      compose(context(), polygon([(1,0.5), (0,1)]))
                                  end=#
          else
              left=iterate_undernode(node.left, true)
              right=iterate_undernode(node.right, false)
              compose(context(),
                      #polygon([(1,1), (0,1), (1/2, 0)]),
                      #rectangle(),
                      (context(1/2,   0, 1/2, 1/2), left),
                      (context(  0, 0, 1/2, 1/2), right))
          end
      end
  #LLRBVisualize end
  end

end
