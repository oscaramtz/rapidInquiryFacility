package rifDataLoaderTool.presentationLayer;


import rifGenericLibrary.presentationLayer.*;
import rifGenericLibrary.system.RIFGenericLibraryMessages;
import rifDataLoaderTool.system.RIFDataLoaderMessages;
import rifDataLoaderTool.system.RIFDataLoaderToolMessages;
import rifDataLoaderTool.fileFormats.DirectoryFileFilter;

import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

import javax.swing.*;
import javax.swing.border.LineBorder;

import java.awt.*;
import java.io.File;

/**
 *
 *
 * <hr>
 * Copyright 2015 Imperial College London, developed by the Small Area
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

public class ShapeFileLoaderDialog 
	implements ActionListener {

	public static void main(String[] args) {
		
		UserInterfaceFactory userInterfaceFactory
			= new UserInterfaceFactory();		
		ShapeFileLoaderDialog dialog = new ShapeFileLoaderDialog(userInterfaceFactory);
		dialog.show();
	}
	
	// ==========================================
	// Section Constants
	// ==========================================

	// ==========================================
	// Section Properties
	// ==========================================
	
	private UserInterfaceFactory userInterfaceFactory;
	
	private JDialog dialog;
	
	
	private OrderedListPanel shapeFileListPanel;
	private JTextField shapeFileBrowseDirectoryTextField;
	
	private JButton browseButton;
	private OKCloseButtonPanel okCloseButtonPanel;
	
	// ==========================================
	// Section Construction
	// ==========================================

	public ShapeFileLoaderDialog(final UserInterfaceFactory userInterfaceFactory) {
		this.userInterfaceFactory = userInterfaceFactory;
		
		String dialogTitle
			= RIFDataLoaderToolMessages.getMessage("shapeFileLoaderDialog.title");
		dialog
			= userInterfaceFactory.createDialog(dialogTitle);
		
		JPanel panel 
			= userInterfaceFactory.createPanel();
		GridBagConstraints panelGC
			= userInterfaceFactory.createGridBagConstraints();
		panelGC.fill = GridBagConstraints.HORIZONTAL;
		panelGC.weightx = 1;
		
		panelGC.fill = GridBagConstraints.HORIZONTAL;
		panelGC.weightx = 1;
		String instructionsText
			= RIFDataLoaderMessages.getMessage("shapeFileLoaderDialog.instructions");	
		JPanel instructionsPanel
			= userInterfaceFactory.createHTMLInstructionPanel(instructionsText);
		panel.add(instructionsPanel, panelGC);
			
		panelGC.gridy++;
		panel.add(createBrowseShapeFilePanel(), panelGC);
		
		//create the list of shape files
		panelGC.gridy++;
		panelGC.fill = GridBagConstraints.BOTH;
		panelGC.weighty = 1;
		String shapeFileListTitle
			= RIFDataLoaderToolMessages.getMessage("shapeFile.name.plural.label");	
		shapeFileListPanel
			= new OrderedListPanel(
				shapeFileListTitle,
				null,
				userInterfaceFactory,
				true);		
		panel.add(shapeFileListPanel.getPanel(), panelGC);
				
		panelGC.gridy++;
		panelGC.fill = GridBagConstraints.NONE;
		panelGC.anchor = GridBagConstraints.SOUTHEAST;
		okCloseButtonPanel
			= new OKCloseButtonPanel(userInterfaceFactory);
		okCloseButtonPanel.addActionListener(this);
		panel.add(okCloseButtonPanel.getPanel(), panelGC);
		dialog.getContentPane().add(panel);
		dialog.setSize(500, 500);
	}

	private JPanel createInstructionPanel() {
		
		String instructionsText
			= RIFDataLoaderToolMessages.getMessage("shapeFileLoaderDialog.instructions");
		JTextArea instructionsTextArea
			= userInterfaceFactory.createNonEditableTextArea(3, 20);
		instructionsTextArea.setText(instructionsText);
		instructionsTextArea.setBorder(LineBorder.createGrayLineBorder());
		
		JPanel panel 
			= userInterfaceFactory.createPanel();
		GridBagConstraints panelGC
			= userInterfaceFactory.createGridBagConstraints();
		panelGC.fill = GridBagConstraints.BOTH;
		panelGC.weightx = 1;
		panelGC.weighty = 1;
		
		panel.add(instructionsTextArea, panelGC);
				
		return panel;
	}
	
	private JPanel createBrowseShapeFilePanel() {
		JPanel panel 
			= userInterfaceFactory.createPanel();
		GridBagConstraints panelGC
			= userInterfaceFactory.createGridBagConstraints();

		shapeFileBrowseDirectoryTextField
			= userInterfaceFactory.createNonEditableTextField();
		panel.add(shapeFileBrowseDirectoryTextField, panelGC);
		
		panelGC.gridy++;
		String browseButtonText
			= RIFGenericLibraryMessages.getMessage("buttons.browse.label");
		browseButton
			= userInterfaceFactory.createButton(browseButtonText);
		browseButton.addActionListener(this);
		panel.add(browseButton, panelGC);
		return panel;
	}
	
	// ==========================================
	// Section Accessors and Mutators
	// ==========================================

	public void updateAvailableShapeFiles() {
		
		
		
		
	}
	
	public void show() {
		dialog.setVisible(true);
	}
	
	private void browse() {
		JFileChooser fileChooser
			= userInterfaceFactory.createFileChooser();
		fileChooser.setFileFilter(new DirectoryFileFilter());
		int result = fileChooser.showOpenDialog(dialog);
		if (result != JFileChooser.APPROVE_OPTION) {
			return;
		}
			
		File selectedDirectory = fileChooser.getSelectedFile();
		shapeFileBrowseDirectoryTextField.setText(selectedDirectory.getAbsolutePath());
	
		//update the total number of shape files that are available
		
		
		updateAvailableShapeFiles();
	}
	
	private void ok() {
		
		
		dialog.setVisible(false);		
	}
	
	private void close() {
		
		dialog.setVisible(false);
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
		
		if (button == browseButton) {
			browse();
		}
		else if (okCloseButtonPanel.isOKButton(button)) {
			ok();
		}
		else if (okCloseButtonPanel.isCloseButton(button)) {
			close();
		}
	}
	
	// ==========================================
	// Section Override
	// ==========================================

}


