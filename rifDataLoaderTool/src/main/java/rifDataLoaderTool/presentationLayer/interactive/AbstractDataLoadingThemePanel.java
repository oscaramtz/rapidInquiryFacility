package rifDataLoaderTool.presentationLayer.interactive;


import rifDataLoaderTool.system.DataLoaderToolSession;
import rifGenericLibrary.presentationLayer.ErrorDialog;
import rifGenericLibrary.presentationLayer.ListEditingButtonPanel;
import rifGenericLibrary.presentationLayer.OrderedListPanel;
import rifGenericLibrary.presentationLayer.UserInterfaceFactory;
import rifGenericLibrary.system.RIFServiceException;
import rifGenericLibrary.presentationLayer.DisplayableListItemInterface;

import javax.swing.*;
import javax.swing.border.LineBorder;

import java.awt.event.*;
import java.awt.*;
import java.util.*;


/**
 *
 *
 * <hr>
 * Copyright 2016 Imperial College London, developed by the Small Area
 * Health Statistics Unit. 
 *
 * <pre> 
 * This file is part of the Rapid Inquiry Facility (RIF) project.
 * RIF is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * RIF is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with RIF.  If not, see <http://www.gnu.org/licenses/>.
 * </pre>
 *
 * <hr>
 * Kevin Garwood
 * @author kgarwood
 */

/*
 * Code Road Map:
 * --------------
 * Code is organised into the following sections.  Wherever possible, 
 * methods are classified based on an order of precedence described in 
 * parentheses (..).  For example, if you're trying to find a method 
 * 'getName(...)' that is both an interface method and an accessor 
 * method, the order tells you it should appear under interface.
 * 
 * Order of 
 * Precedence     Section
 * ==========     ======
 * (1)            Section Constants
 * (2)            Section Properties
 * (3)            Section Construction
 * (7)            Section Accessors and Mutators
 * (6)            Section Errors and Validation
 * (5)            Section Interfaces
 * (4)            Section Override
 *
 */

public abstract class AbstractDataLoadingThemePanel 
	implements ActionListener, 
	Observer {

	// ==========================================
	// Section Constants
	// ==========================================
	private static final Color populatedColour = Color.GREEN;
	private static final Color unpopulatedColour = Color.BLACK;
	private static final Color disabledColour = Color.BLACK;
	
	// ==========================================
	// Section Properties
	// ==========================================
	private JFrame frame;
	private DataLoaderToolSession session;
	private UserInterfaceFactory userInterfaceFactory;
	private DLDependencyManager dependencyManager;	
	private OrderedListPanel listPanel;
	private ListEditingButtonPanel listEditingButtonPanel;	
	private JPanel mainPanel;
	
	// ==========================================
	// Section Construction
	// ==========================================

	public AbstractDataLoadingThemePanel(
		final JFrame frame,
		final DataLoaderToolSession session,
		final DLDependencyManager dependencyManager) {

		this.frame = frame;
		this.session = session;
		this.userInterfaceFactory = session.getUserInterfaceFactory();
		this.dependencyManager = dependencyManager;

		listPanel 
			= new OrderedListPanel(userInterfaceFactory);
		listPanel.setUseDefaultSelectionPolicy(true);
		listEditingButtonPanel
			= new ListEditingButtonPanel(userInterfaceFactory);
		listEditingButtonPanel.includeAddButton("");
		listEditingButtonPanel.includeEditButton("");
		listEditingButtonPanel.includeDeleteButton("");
		listEditingButtonPanel.addActionListener(this);
	}
	
	protected void setListTitle(final String titleText) {
		listPanel.setListTitle(titleText, true);
	}


	protected void buildUI() {
		mainPanel = userInterfaceFactory.createPanel();
		GridBagConstraints panelGC 
			= userInterfaceFactory.createGridBagConstraints();
		panelGC.anchor = GridBagConstraints.NORTHWEST;
		panelGC.fill = GridBagConstraints.BOTH;
		panelGC.weightx = 1;
		panelGC.weighty = 1;	
		mainPanel.add(listPanel.getPanel(), panelGC);
		
		panelGC.gridy++;
		panelGC.anchor = GridBagConstraints.SOUTHEAST;
		panelGC.fill = GridBagConstraints.NONE;
		panelGC.weightx = 0;
		panelGC.weighty = 0;
		mainPanel.add(listEditingButtonPanel.getPanel(), panelGC);
		mainPanel.setBorder(LineBorder.createGrayLineBorder());
	}	

	public void setEnable(final boolean isEnabled) {

		listPanel.setEnabled(isEnabled);
		if (isEnabled) {
			updateListButtonStates();
		}
		else {
			listPanel.setListLabelColour(disabledColour);
			listEditingButtonPanel.disableAllButtons();
		}
	}
	
	private void updateListButtonStates() {
		if (listPanel.isEmpty()) {
			listPanel.setListLabelColour(unpopulatedColour);			
			listEditingButtonPanel.indicateEmptyState();
		}
		else {
			listPanel.setListLabelColour(populatedColour);			
			listEditingButtonPanel.indicatePopulatedState();
		}
		
	}
	
	
	// ==========================================
	// Section Accessors and Mutators
	// ==========================================
	
	public JFrame getFrame() {
		return frame;
	}
	
	public JPanel getPanel() {
		return mainPanel;
	}
	
	public DataLoaderToolSession getSession() {
		return session;
	}
	
	public UserInterfaceFactory getUserInterfaceFactory() {
		return userInterfaceFactory;
	}
	
	protected void addListItem(final DisplayableListItemInterface listItem) {
		listPanel.addListItem(listItem);
	}
	
	protected void updateListItem(
		final DisplayableListItemInterface originalItem, 
		final DisplayableListItemInterface revisedItem) {
		
		listPanel.replaceItem(originalItem, revisedItem);
	}
	
	protected abstract void addListItem();	
	protected abstract void editSelectedListItem();
	protected abstract void checkDependenciesForItemsToDelete()
		throws RIFServiceException;
	
	protected DLDependencyManager getDependencyManager() {
		return dependencyManager;
	}
	
	public ArrayList<DisplayableListItemInterface> getSelectedListItems() {
		return listPanel.getSelectedItems();
	}

	public DisplayableListItemInterface getSelectedListItem() {
		return listPanel.getSelectedItem();
	}
	
	// ==========================================
	// Section Errors and Validation
	// ==========================================

	// ==========================================
	// Section Interfaces
	// ==========================================

	//Interface: Action Listener
	public void actionPerformed(final ActionEvent event) {
		Object button = event.getSource();
		
		try {			
			if (listEditingButtonPanel.isAddButton(button)) {
				addListItem();
			}
			else if (listEditingButtonPanel.isEditButton(button)) {
				editSelectedListItem();
			}
			else if (listEditingButtonPanel.isDeleteButton(button)) {
				checkDependenciesForItemsToDelete();
				listPanel.deleteSelectedListItems();
			}	
			
		}
		catch(RIFServiceException rifServiceException) {
			ErrorDialog.showError(
				frame, 
				rifServiceException.getMessage());
		}

	}
	
	//Interface: Observer
	public abstract void update(
		final Observable observable,
	    final Object editingState);
	
	// ==========================================
	// Section Override
	// ==========================================

}


