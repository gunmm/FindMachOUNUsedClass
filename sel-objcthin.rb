require "objcthin/version"
require 'thor'
require 'rainbow'
require 'pathname'
require 'singleton'

path = "/Users/minzhe/Desktop/JiemianNews"

all_sels = []
used_sel = []
unused_sel = []

apple_protocols = [
'tableView:canEditRowAtIndexPath:',
'commitEditingStyle:forRowAtIndexPath:',
'tableView:viewForHeaderInSection:',
'tableView:cellForRowAtIndexPath:',
'tableView:canPerformAction:forRowAtIndexPath:withSender:',
'tableView:performAction:forRowAtIndexPath:withSender:',
'tableView:accessoryButtonTappedForRowWithIndexPath:',
'tableView:willDisplayCell:forRowAtIndexPath:',
'tableView:commitEditingStyle:forRowAtIndexPath:',
'tableView:didEndDisplayingCell:forRowAtIndexPath:',
'tableView:didEndDisplayingHeaderView:forSection:',
'tableView:heightForFooterInSection:',
'tableView:shouldHighlightRowAtIndexPath:',
'tableView:shouldShowMenuForRowAtIndexPath:',
'tableView:viewForFooterInSection:',
'tableView:willDisplayHeaderView:forSection:',
'tableView:willSelectRowAtIndexPath:',
'tableView:numberOfRowsInSection:',
'numberOfSectionsInCollectionView:',
'collectionView:numberOfItemsInSection:',
'collectionView:cellForItemAtIndexPath:',
'collectionView:willDisplayCell:forItemAtIndexPath:',
'collectionView:layout:sizeForItemAtIndexPath:',
'collectionView:layout:minimumLineSpacingForSectionAtIndex:',
'collectionView:layout:minimumInteritemSpacingForSectionAtIndex:',
'willMoveToSuperview:',
'scrollViewDidEndScrollingAnimation:',
'scrollViewDidZoom',
'scrollViewWillEndDragging:withVelocity:targetContentOffset:',
'searchBarTextDidEndEditing:',
'searchBar:selectedScopeButtonIndexDidChange:',
'shouldInvalidateLayoutForBoundsChange:',
'textFieldShouldReturn:',
'numberOfSectionsInTableView:',
'actionSheet:willDismissWithButtonIndex:',
'gestureRecognizer:shouldReceiveTouch:',
'gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:',
'gestureRecognizer:shouldReceiveTouch:',
'imagePickerController:didFinishPickingMediaWithInfo:',
'imagePickerControllerDidCancel:',
'animateTransition:',
'animationControllerForDismissedController:',
'animationControllerForPresentedController:presentingController:sourceController:',
'navigationController:animationControllerForOperation:fromViewController:toViewController:',
'navigationController:interactionControllerForAnimationController:',
'alertView:didDismissWithButtonIndex:',
'URLSession:didBecomeInvalidWithError:',
'setDownloadTaskDidResumeBlock:',
'tabBarController:didSelectViewController:',
'tabBarController:shouldSelectViewController:',
'applicationDidReceiveMemoryWarning:',
'application:didRegisterForRemoteNotificationsWithDeviceToken:',
'application:didFailToRegisterForRemoteNotificationsWithError:',
'application:didReceiveRemoteNotification:fetchCompletionHandler:',
'application:didRegisterUserNotificationSettings:',
'application:performActionForShortcutItem:completionHandler:',
'application:continueUserActivity:restorationHandler:'].freeze

# imp -[class sel]

sub_patten = /[+|-]\[.+\s(.+)\]/
sel_set_patten = /set[A-Z].*:$/
sel_get_patten = /is[A-Z].*/

name_patten_string = '.*'
namePatten = /      name (#{name_patten_string}) (#{name_patten_string})/
patten = /       imp (#{name_patten_string})/
classNamePatten = /                     name (#{name_patten_string}) (#{name_patten_string})/

ivarsBeginPatten = /                    ivars 0x(#{name_patten_string})/
ivarsEndPatten = /           weakIvarLayout 0x(#{name_patten_string})/
ivarNamePatten = /     name 0x(#{name_patten_string}) _(#{name_patten_string})/

class_list_identifier = 'Contents of (__DATA,__objc_classlist) section'
sectionPatten = /Contents of \(.*\) section/


output = `/usr/bin/otool -oV #{path}`

imp = {}
n = 0
lastStr = ''
classStr = ''

can_add_to_ivars = false
can_add_to_list = false

ivars = []
class_list = []

output.each_line do |line|
    if sectionPatten.match(line)
        if line.include? class_list_identifier
            can_add_to_list = true
            next
            else
            can_add_to_list = false
            break
        end
    end
    if can_add_to_list
        class_list << line
    end
end

class_list.each do |line|
    n = n + 1
    namePatten.match(line) do |m|
        lastStr = m[2]
        n = 0
    end

    classNamePatten.match(line) do |m|
        classStr = m[2]
    end
    
    patten.match(line) do |m|
      if n == 2
          next if lastStr.start_with?('.')
          next if classStr.start_with?('_')
          next if apple_protocols.include?(lastStr)
          next if sel_set_patten.match?(lastStr)
          next if sel_get_patten.match?(lastStr)
          imp[lastStr] = (classStr + " " + lastStr)
      end
    end
    
    ivarsBeginPatten.match(line) do |m|
        can_add_to_ivars = true
    end
    
    if can_add_to_ivars
        ivarNamePatten.match(line) do |m|
            ivars << m[2]
        end
    end
    
    ivarsEndPatten.match(line) do |m|
        can_add_to_ivars = false
    end
end

patten = /__TEXT:__objc_methname:(.+)/
output = `/usr/bin/otool -v -s __DATA __objc_selrefs #{path}`

sels = []
output.each_line do |line|
  patten.match(line) do |m|
    sels << m[1]
  end
end

unused_sel = []
puts imp.values.count

imp.each do |sel,class_and_sels|
  if ivars.include?(sel)
      imp.delete(sel)
  end
end

puts imp.values.count

imp.each do |sel,class_and_sels|
  unless sels.include?(sel)
    unused_sel << class_and_sels
  end
end

puts unused_sel.count
puts unused_sel.sort
