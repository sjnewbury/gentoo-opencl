# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI="git://anongit.freedesktop.org/mesa/mesa"

if [[ ${PV} = 9999* ]]; then
	GIT_ECLASS="git-r3"
	EXPERIMENTAL="true"
	B_PV="${PV}"
	V_PV="${PV}"
	VULKAN_BRANCH=vulkan
else
	B_PV="0.9"
fi

inherit cmake-utils base autotools multilib multilib-minimal flag-o-matic \
	python-utils-r1 toolchain-funcs pax-utils ${GIT_ECLASS}

OPENGL_DIR="xorg-x11"

MY_PN="${PN/m/M}"
MY_P="${MY_PN}-${PV/_/-}"
MY_SRC_P="${MY_PN}Lib-${PV/_/-}"

FOLDER="${PV/_rc*/}"

DESCRIPTION="OpenGL-like graphic library for Linux"
HOMEPAGE="http://mesa3d.sourceforge.net/"

#SRC_PATCHES="mirror://gentoo/${P}-gentoo-patches-01.tar.bz2"
if [[ $PV = 9999* ]]; then
	SRC_URI="${SRC_PATCHES}"
else
	SRC_URI="ftp://ftp.freedesktop.org/pub/mesa/${FOLDER}/${MY_SRC_P}.tar.bz2
		${SRC_PATCHES}
		http://cgit.freedesktop.org/beignet/snapshot/Release_v${B_PV}.tar.gz"
fi

LICENSE="MIT"
SLOT="0"
RESTRICT="!bindist? ( bindist )"

INTEL_CARDS="i915 i965 ilo intel"
RADEON_CARDS="r100 r200 r300 r600 radeon radeonsi"
VIDEO_CARDS="${INTEL_CARDS} ${RADEON_CARDS} freedreno nouveau vmware virgl"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS}
	bindist +classic d3d9 debug +dri3 +egl +gallium +gbm gles1 gles2 +llvm
	+nptl opencl osmesa pax_kernel openmax pic selinux +udev vaapi vdpau
	wayland xvmc xa kernel_FreeBSD beignet beignet-egl beignet-generic
	opencl-icd glvnd vulkan"

#  Not available at present unfortunately
#	openvg? ( egl gallium )

REQUIRED_USE="
	llvm?   ( gallium )
	d3d9?   ( dri3 gallium )
	opencl? (
		video_cards_r600? ( gallium )
		video_cards_radeon? ( gallium )
		video_cards_radeonsi? ( gallium )
		video_cards_i965? ( beignet )
		video_cards_ilo? ( beignet )
		video_cards_intel? ( beignet )
	)
	openmax? ( gallium )
	gles1?  ( egl )
	gles2?  ( egl )
	vaapi? ( gallium )
	vdpau? ( gallium )
	wayland? ( egl gbm )
	xa?  ( gallium )
	video_cards_freedreno?  ( gallium )
	video_cards_intel?  ( || ( classic ) )
	video_cards_i915?   ( || ( classic gallium ) )
	video_cards_i965?   ( classic )
	video_cards_ilo?    ( gallium )
	video_cards_nouveau? ( || ( classic gallium ) )
	video_cards_radeon? ( || ( classic gallium ) )
	video_cards_r100?   ( classic )
	video_cards_r200?   ( classic )
	video_cards_r300?   ( gallium )
	video_cards_r600?   ( gallium )
	video_cards_radeonsi?   ( gallium llvm )
	video_cards_vmware? ( gallium )
	video_cards_virgl? ( gallium )
"

LIBDRM_DEPSTRING=">=x11-libs/libdrm-2.4.64"
# keep correct libdrm and dri2proto dep
# keep blocks in rdepend for binpkg
RDEPEND="
	!<x11-base/xorg-server-1.7
	!<=x11-proto/xf86driproto-2.0.3
	abi_x86_32? ( !app-emulation/emul-linux-x86-opengl[-abi_x86_32(-)] )
	classic? ( app-eselect/eselect-mesa )
	gallium? ( app-eselect/eselect-mesa )
	>=app-eselect/eselect-opengl-1.3.0
	udev? ( kernel_linux? ( >=virtual/libudev-215:=[${MULTILIB_USEDEP}] ) )
	>=dev-libs/expat-2.1.0-r3:=[${MULTILIB_USEDEP}]
	gbm? ( >=virtual/libudev-215:=[${MULTILIB_USEDEP}] )
	dri3? ( >=virtual/libudev-215:=[${MULTILIB_USEDEP}] )
	>=x11-libs/libX11-1.6.2:=[${MULTILIB_USEDEP}]
	>=x11-libs/libxshmfence-1.1:=[${MULTILIB_USEDEP}]
	>=x11-libs/libXdamage-1.1.4-r1:=[${MULTILIB_USEDEP}]
	>=x11-libs/libXext-1.3.2:=[${MULTILIB_USEDEP}]
	>=x11-libs/libXxf86vm-1.1.3:=[${MULTILIB_USEDEP}]
	>=x11-libs/libxcb-1.9.3:=[${MULTILIB_USEDEP}]
	x11-libs/libXfixes:=[${MULTILIB_USEDEP}]
	llvm? ( !kernel_FreeBSD? (
		video_cards_radeonsi? ( || (
			>=dev-libs/elfutils-0.155-r1:=[${MULTILIB_USEDEP}]
			>=dev-libs/libelf-0.8.13-r2:=[${MULTILIB_USEDEP}]
			) )
		!video_cards_r600? (
			video_cards_radeon? ( || (
				>=dev-libs/elfutils-0.155-r1:=[${MULTILIB_USEDEP}]
				>=dev-libs/libelf-0.8.13-r2:=[${MULTILIB_USEDEP}]
				) )
		) )
		>=sys-devel/llvm-3.7.0:=[${MULTILIB_USEDEP}]
	)
	opencl? (
				app-eselect/eselect-opencl
				beignet? ( 	!dev-libs/beignet
						opencl-icd? ( dev-libs/ocl-icd )
					 )
				gallium? (
					dev-libs/libclc
					|| (
						>=dev-libs/elfutils-0.155-r1:=[${MULTILIB_USEDEP}]
						>=dev-libs/libelf-0.8.13-r2:=[${MULTILIB_USEDEP}]
						opencl-icd? ( dev-libs/ocl-icd )
					)
				)
			)
	openmax? ( >=media-libs/libomxil-bellagio-0.9.3:=[${MULTILIB_USEDEP}] )
	vaapi? ( >=x11-libs/libva-0.35.0:=[${MULTILIB_USEDEP}] )
	vdpau? ( >=x11-libs/libvdpau-0.7:=[${MULTILIB_USEDEP}] )
	wayland? ( >=dev-libs/wayland-1.2.0:=[${MULTILIB_USEDEP}] )
	xvmc? ( >=x11-libs/libXvMC-1.0.8:=[${MULTILIB_USEDEP}] )
	${LIBDRM_DEPSTRING}[video_cards_freedreno?,video_cards_nouveau?,video_cards_vmware?,video_cards_virgl?,${MULTILIB_USEDEP}]
"
for card in ${INTEL_CARDS}; do
	RDEPEND="${RDEPEND}
		video_cards_${card}? (
								${LIBDRM_DEPSTRING}[video_cards_intel]
								opencl? ( beignet? ( || (
									>=sys-devel/llvm-3.3[${MULTILIB_USEDEP}]
									>=sys-devel/llvm-3.4[-ncurses,${MULTILIB_USEDEP}]
										)
										!beignet-generic? ( sys-apps/pciutils ) )
								)
		)
	"
done

for card in ${RADEON_CARDS}; do
	RDEPEND="${RDEPEND}
		video_cards_${card}? (
								${LIBDRM_DEPSTRING}[video_cards_radeon]
								opencl? (
											>=sys-devel/llvm-3.3-r1[video_cards_radeon,${MULTILIB_USEDEP}]
											dev-libs/libclc[${MULTILIB_USEDEP}]
								)
		)
	"
done
RDEPEND="${RDEPEND}
	video_cards_radeonsi? ( ${LIBDRM_DEPSTRING}[video_cards_amdgpu] )
"

DEPEND="${RDEPEND}
	llvm? (
		video_cards_radeonsi? ( sys-devel/llvm[video_cards_radeon] )
	)
	opencl? (
				>=sys-devel/llvm-3.7:=[${MULTILIB_USEDEP}]
				>=sys-devel/clang-3.7:=[${MULTILIB_USEDEP}]
				>=sys-devel/gcc-4.6
	)
	sys-devel/gettext
	virtual/pkgconfig
	beignet? ( sys-apps/sed )
	>=x11-proto/dri2proto-2.8-r1:=[${MULTILIB_USEDEP}]
	dri3? (
		>=x11-proto/dri3proto-1.0:=[${MULTILIB_USEDEP}]
		>=x11-proto/presentproto-1.0:=[${MULTILIB_USEDEP}]
	)
	>=x11-proto/glproto-1.4.17-r1:=[${MULTILIB_USEDEP}]
	>=x11-proto/xextproto-7.2.1-r1:=[${MULTILIB_USEDEP}]
	>=x11-proto/xf86driproto-2.1.1-r1:=[${MULTILIB_USEDEP}]
	>=x11-proto/xf86vidmodeproto-2.3.1-r1:=[${MULTILIB_USEDEP}]
	dev-lang/python:2.7
	vulkan? ( =dev-lang/python-3* )
	>=dev-python/mako-0.7.3[python_targets_python2_7]
"
[[ ${PV} == 9999 ]] && DEPEND+="
	sys-devel/bison
	sys-devel/flex
"

S="${WORKDIR}/${MY_P}"
CMAKE_USE_DIR="${S}"/beignet-${B_PV}

QA_WX_LOAD="
x86? (
	!pic? (
		usr/lib*/libglapi.so.0.0.0
		usr/lib*/libGLESv1_CM.so.1.1.0
		usr/lib*/libGLESv2.so.2.0.0
		usr/lib*/libGL.so.1.2.0
		usr/lib*/libOSMesa.so.8.0.0
	)
)"

pkg_setup() {
	# warning message for bug 459306
	if use llvm && has_version sys-devel/llvm[!debug=]; then
		ewarn "Mismatch between debug USE flags in media-libs/mesa and sys-devel/llvm"
		ewarn "detected! This can cause problems. For details, see bug 459306."
	fi
	use vulkan && [[ ${PV} != 9999 ]] && die "Vulkan is currently git only"
}

beignet_src_unpack() {
		export EGIT_MIN_CLONE_TYPE=shallow
		if [ -n "${BEIGNET_COMMIT}" ]; then
			git-r3_fetch "git://anongit.freedesktop.org/beignet" \
				"${BEIGNET_COMMIT}"
		elif [ -n "${BEIGNET_BRANCH}" ]; then
			git-r3_fetch "git://anongit.freedesktop.org/beignet" \
				"refs/heads/${BEIGNET_BRANCH}"
		elif [ -n "${BEIGNET_TAG}" ]; then
			git-r3_fetch "git://anongit.freedesktop.org/beignet" \
				"refs/tags/${BEIGNET_TAG}"
		else
			git-r3_fetch "git://anongit.freedesktop.org/beignet" \
				"refs/heads/master"
		fi		
		git-r3_checkout "git://anongit.freedesktop.org/beignet" \
			"${S}"/beignet-${B_PV}
}

glvnd_src_unpack() {
		export EGIT_MIN_CLONE_TYPE=mirror
		# Clone Mesa branch (EGIT_REPO_URI)
		git-r3_checkout "" "${S}"/glvnd_build "${CATEGORY}/${PN}/${SLOT%/*}-MesaGL"
}

vulkan_src_unpack() {
		export EGIT_MIN_CLONE_TYPE=mirror
		# Same repo as Mesa (EGIT_REPO_URI)
		if [ -n "${VULKAN_COMMIT}" ]; then
			git-r3_fetch "" "${VULKAN_COMMIT}" "${CATEGORY}/${PN}/${SLOT%/*}-MesaVulkan"
		elif [ -n "${VULKAN_BRANCH}" ]; then
			git-r3_fetch "" "refs/heads/${VULKAN_BRANCH}" "${CATEGORY}/${PN}/${SLOT%/*}-MesaVulkan"
		elif [ -n "${VULKAN_TAG}" ]; then
			git-r3_fetch "" "refs/tags/${VULKAN_TAG}" "${CATEGORY}/${PN}/${SLOT%/*}-MesaVulkan"
		else
			git-r3_fetch "" "refs/heads/master" "${CATEGORY}/${PN}/${SLOT%/*}-MesaVulkan"
		fi		
		git-r3_checkout "" "${S}"/vulkan-${V_PV} "${CATEGORY}/${PN}/${SLOT%/*}-MesaVulkan"
}

src_unpack() {
	default
	if [[ $PV = 9999* ]] ; then
		export EGIT_MIN_CLONE_TYPE=mirror
		git-r3_fetch "" "" "${CATEGORY}/${PN}/${SLOT%/*}-MesaGL"
		git-r3_checkout "" "${S}" "${CATEGORY}/${PN}/${SLOT%/*}-MesaGL"
		use opencl && use beignet && beignet_src_unpack
		# Until vulkan is merged with mesa proper, check out vulkan
		# branch
		use vulkan && vulkan_src_unpack
		use glvnd && glvnd_src_unpack

		# We want to make sure the mesa repo HEAD gets stored not beignet
		# so set the EGIT_VERSION ourselves. 
		cd "${S}"
		local new_commit_id=$(
			git rev-parse --verify HEAD
		)
		export EGIT_VERSION=${new_commit_id}
	else
		# keep beignet sources in mesa source tree so they 
		# get copied with for multilib build
  		use beignet && mv "${WORKDIR}"/beignet-${B_PV} "${S}"
		if use glvnd ; then
			ebegin "Copying Mesa sources for GLVND build"
			cp -p -R "${S}" "${T}"/glvnd_build
			mv "${T}"/glvnd_build "${S}"
			eend $?
		fi
	fi
}

beignet_src_prepare() {
	pushd "${S}"/beignet-${B_PV}
	cmake-utils_src_prepare

	# Fix linking
	# no longer needed
	#epatch "${FILESDIR}"/beignet-"${B_PV}"-respect-flags.patch

	# Build beignet libcl as libOpenCL so that it can be handled
	# by the Gentoo eselect opencl
	if [[ -n "${BEIGNET_BRANCH}"  ]]; then
		epatch "${FILESDIR}"/beignet-${BEIGNET_BRANCH}-"${B_PV}"-libOpenCL.patch
		epatch "${FILESDIR}"/beignet-${BEIGNET_BRANCH}-"${B_PV}"-inline-to-static-inline.patch
	else
		epatch "${FILESDIR}"/beignet-"${B_PV}"-libOpenCL.patch
	fi
#	epatch "${FILESDIR}"/beignet-"${B_PV}"-fix-FindLLVM.patch
	epatch "${FILESDIR}"/beignet-"${B_PV}"-llvm-libs-tr.patch
	#epatch "${FILESDIR}"/beignet-"${B_PV}"-buildfix.patch
	epatch "${FILESDIR}"/beignet-"${B_PV}"-bitcode-path-fix.patch
	epatch "${FILESDIR}"/beignet-"${B_PV}"-silence-dri2-failure.patch
#	epatch "${FILESDIR}"/fix-beignet.patch

	# Beignet hasn't been converted to use the new PassManager yet
#	sed -i -e 's/\(PassManager\.h\)/IR\/Legacy\1/' $(find -name '*.cpp')
#	sed -i -e 's/\(::PassManager\)/::legacy\1/' $(find -name '*.cpp')

#	Change ICD name as above
	sed -i -e 's/libcl/libOpenCL/g' intel-beignet.icd.in

	# optionally enable support for ICD
	use opencl-icd || sed -i -e '/Find_Package(OCLIcd)/s/^/#/' \
		CMakeLists.txt || die
	popd
}

apply_mesa_patches() {
	# apply patches
	if [[ ${PV} != 9999* && -n ${SRC_PATCHES} ]]; then
		EPATCH_FORCE="yes" \
		EPATCH_SOURCE="${WORKDIR}/patches" \
		EPATCH_SUFFIX="patch" \
		epatch
	fi

	# relax the requirement that r300 must have llvm, bug 380303
	#epatch "${FILESDIR}"/${P}-dont-require-llvm-for-r300.patch

	# fix for hardened pax_kernel, bug 240956
	[[ ${PV} != 9999* ]] && epatch "${FILESDIR}"/glx_ro_text_segm.patch

	# Solaris needs some recent POSIX stuff in our case
	if [[ ${CHOST} == *-solaris* ]] ; then
		sed -i -e "s/-DSVR4/-D_POSIX_C_SOURCE=200112L/" configure.ac || die
	fi
}

src_prepare() {
	apply_mesa_patches

	base_src_prepare

	eautoreconf

	if use glvnd ; then
		pushd "${S}"/glvnd_build
			apply_mesa_patches

			# libglvnd patches
			epatch "${FILESDIR}"/0001-Add-an-flag-to-not-export-GL-and-GLX-functions.patch
			epatch "${FILESDIR}"/0002-GLX-Implement-the-libglvnd-interface.patch
			epatch "${FILESDIR}"/0003-Update-to-match-libglvnd-commit-e356f84554da42825e14.patch
			epatch "${FILESDIR}"/fix-GL_LIBS-linking.patch

			base_src_prepare

			eautoreconf
		popd
	fi

	# prepare beignet (intel opencl support) using cmake
	use opencl && use beignet && beignet_src_prepare

	if use vulkan ; then
		pushd "${S}"/vulkan-${V_PV}
			epatch "${FILESDIR}"/0001-Revert-anv-formats-Don-t-use-a-compound-literal-to-i.patch
			eautoreconf
		popd
	fi

	multilib_copy_sources

}

glvnd_src_configure() {
	pushd "${BUILD_DIR}"/glvnd_build
	# For now only GLX is supported, shared glapi will only work when
	# glvnd stops using its own internal copy
	ECONF_SOURCE="${S}/glvnd_build" \
	econf \
		${myconf} \
		--enable-dri \
		--enable-glx \
		--disable-shared-glapi \
		--disable-gles1 \
		--disable-gles2 \
		--disable-gbm \
		--disable-egl \
		--disable-glx-tls \
		$(use_enable !bindist texture-float) \
		$(use_enable debug) \
		$(use_enable dri3) \
		--disable-osmesa \
		$(use_enable !udev sysfs) \
		--enable-llvm-shared-libs \
		--without-dri-drivers \
		--without-gallium-drivers \
		--enable-libglvnd \
		--disable-nine \
		--disable-opencl \
		PYTHON2="${PYTHON}"
	popd
}

vulkan_src_configure() {
	pushd "${BUILD_DIR}"/vulkan-${B_PV}
	ECONF_SOURCE="${S}"/vulkan-${V_PV} \
	econf \
		$(use_enable !bindist texture-float) \
		$(use_enable debug) \
		$(use_enable !udev sysfs) \
		--with-dri-drivers=${DRI_DRIVERS} \
		--with-gallium-drivers= \
		PYTHON2="${PYTHON}" \
		--disable-nine \
		--disable-gallium-llvm \
		--disable-omx \
		--disable-va \
		--disable-vdpau \
		--disable-xa \
		--disable-xvmc \
		${eglconf}
	popd
}

beignet_src_configure() {
	pushd "${BUILD_DIR}"/beignet-${B_PV}
	local OLD_CFLAGS=${CFLAGS}
	local OLD_CXXFLAGS=${CFLAGS}
	local mycmakeargs=(
		-DBEIGNET_INSTALL_DIR="/usr/$(get_libdir)/OpenCL/vendors/beignet"
	)

	if ! use beignet-generic; then
		mycmakeargs+=(
			-DGEN_PCI_ID=$(. "${FILESDIR}"/GetGenID.sh)
		)
	fi
	if use beignet-egl; then
		mycmakeargs+=(
			-DMESA_SOURCE_PREFIX="${BUILD_DIR}"
		)
	fi

	multilib_is_native_abi || mycmakeargs+=(
		-DLLVM_CONFIG_EXECUTABLE="${EPREFIX}/usr/bin/$(get_abi_CHOST ${ABI})-llvm-config"
	)
	# Use clang (we're depending upon it anyway)
	# and clang doesn't support graphite
	# [currently doesn't work as beignet uses g++ variable length array extension]
	#CC=clang CXX=clang++

	if [[ ${CC} == clang ]]; then
		filter-flags -f*graphite -f*loop-*
		filter-flags -mfpmath* -freorder-blocks-and-partition
	fi

	# Pre-compiled headers otherwise result in redefined symbols (gcc only)
	if [[ ${CC} == gcc* ]]; then
		append-flags -fpch-deps
	fi

	BUILD_DIR=${BUILD_DIR}/beignet-${B_PV} cmake-utils_src_configure
	CFLAGS=${OLD_CFLAGS}
	CXXFLAGS=${OLD_CXXFLAGS}
	popd
}

multilib_src_configure() {
	# Most Mesa Python build scripts are Python2
	python_export python2.7 PYTHON

	local myconf eglconf

	if use classic; then
		# Configurable DRI drivers
		driver_enable swrast

		# Intel code
		driver_enable video_cards_i915 i915
		driver_enable video_cards_i965 i965
		if ! use video_cards_i915 && \
			! use video_cards_i965 && \
				! use video_cards_ilo; then
			driver_enable video_cards_intel i915 i965
		fi

		# Nouveau code
		driver_enable video_cards_nouveau nouveau

		# ATI code
		driver_enable video_cards_r100 radeon
		driver_enable video_cards_r200 r200
		if ! use video_cards_r100 && \
				! use video_cards_r200; then
			driver_enable video_cards_radeon radeon r200
		fi
	fi

	if use egl; then
		eglconf+="--with-egl-platforms=x11$(use wayland && echo ",wayland")$(use gbm && echo ",drm") "
	fi

# FIXME
#			$(use_enable openvg)
#			$(use_enable openvg gallium-egl)

	if use gallium; then
		myconf+="
			$(use_enable d3d9 nine)
			$(use_enable llvm gallium-llvm)
			$(use_enable openmax omx)
			$(use_enable vaapi va)
			$(use_enable vdpau)
			$(use_enable xa)
			$(use_enable xvmc)
		"

		use vaapi && myconf+=" --with-va-libdir=/usr/$(get_libdir)/va/drivers"

		gallium_enable swrast
		gallium_enable video_cards_vmware svga
		gallium_enable video_cards_virgl virgl
		gallium_enable video_cards_nouveau nouveau
		gallium_enable video_cards_i915 i915
		gallium_enable video_cards_ilo ilo
		if ! use video_cards_i915 && \
			! use video_cards_ilo; then
			gallium_enable video_cards_intel i915 ilo
		fi

		gallium_enable video_cards_r300 r300
		gallium_enable video_cards_r600 r600
		gallium_enable video_cards_radeonsi radeonsi
		if ! use video_cards_r300 && \
				! use video_cards_r600; then
			gallium_enable video_cards_radeon r300 r600
		fi

		gallium_enable video_cards_freedreno freedreno
		# opencl stuff
		if use opencl; then
			myconf+="
				$(use_enable opencl)
				$(use_enable opencl-icd)
				--with-opencl-libdir="${EPREFIX}/usr/$(get_libdir)/OpenCL/vendors/mesa"
				--with-clang-libdir="${EPREFIX}/usr/${LIBDIR_default}"
				"
		fi
	fi

	# x86 hardened pax_kernel needs glx-rts, bug 240956
	if [[ ${ABI} == x86 ]]; then
		myconf+=" $(use_enable pax_kernel glx-read-only-text)"
	fi

	# on abi_x86_32 hardened we need to have asm disable
	if [[ ${ABI} == x86* ]] && use pic; then
		myconf+=" --disable-asm"
	fi

	# build fails with BSD indent, bug #428112
	use userland_GNU || export INDENT=cat

	if ! multilib_is_native_abi; then
			LLVM_CONFIG="${EPREFIX}/usr/bin/llvm-config.${ABI}"
	fi

	ECONF_SOURCE="${S}" \
	econf \
		--enable-dri \
		--enable-glx \
		--enable-shared-glapi \
		$(use_enable !bindist texture-float) \
		$(use_enable d3d9 nine) \
		$(use_enable debug) \
		$(use_enable dri3) \
		$(use_enable egl) \
		$(use_enable gbm) \
		$(use_enable gles1) \
		$(use_enable gles2) \
		$(use_enable nptl glx-tls) \
		$(use_enable osmesa) \
		$(use_enable !udev sysfs) \
		--enable-llvm-shared-libs \
		--with-dri-drivers=${DRI_DRIVERS} \
		--with-gallium-drivers=${GALLIUM_DRIVERS} \
		PYTHON2="${PYTHON}" \
		${eglconf} \
		${myconf}

	use vulkan && vulkan_src_configure
	use glvnd && glvnd_src_configure

	# intel opencl stuff
	use opencl && use beignet && beignet_src_configure
}

#		$(use_enable !pic asm) \

multilib_src_compile() {
	default
	
	if use vulkan ; then
		pushd "${BUILD_DIR}"/vulkan-${V_PV}
			# Vulkan Python build scripts are Python3!
			python_export python3 PYTHON
			emake
		popd
	fi

	if use glvnd ; then
		pushd "${BUILD_DIR}"/glvnd_build
			emake
		popd
	fi

	if use opencl && use beignet ; then
		pushd "${BUILD_DIR}"/beignet-${B_PV}
		emake
		popd
	fi	
}

multilib_src_install() {
	emake install DESTDIR="${D}"

	if use glvnd ; then
		pushd "${BUILD_DIR}"/glvnd_build
			ebegin "Installing glvnd-mesa libs to glvnd directory"
			local glvnd_dir="/usr/$(get_libdir)/opengl/glvnd/"
			dodir ${glvnd_dir}/lib
			insinto ${glvnd_dir}/lib
			doins lib*/*.so
		eend $?
		popd
	fi

	if use vulkan ; then
		pushd "${BUILD_DIR}"/vulkan-${V_PV}
			emake install DESTDIR="${D}"
			ebegin "Installing Vulkan ICD json manifest file(s)"
			dodir /etc/vulkan/icd.d
			local vulkan_drivers=( intel )
			for x in ${vulkan_drivers[@]}; do
				doins src/${x}/vulkan/${x}_icd.json
			done
			eend $?
		popd
	fi

	if use classic || use gallium; then
			ebegin "Moving DRI/Gallium drivers for dynamic switching"
			local gallium_drivers=( i915_dri.so i965_dri.so r300_dri.so r600_dri.so swrast_dri.so )
			keepdir /usr/$(get_libdir)/dri
			dodir /usr/$(get_libdir)/mesa
			for x in ${gallium_drivers[@]}; do
				if [ -f "$(get_libdir)/gallium/${x}" ]; then
					mv -f "${ED}/usr/$(get_libdir)/dri/${x}" "${ED}/usr/$(get_libdir)/dri/${x/_dri.so/g_dri.so}" \
						|| die "Failed to move ${x}"
				fi
			done
			if use classic; then
				emake -C "${BUILD_DIR}/src/mesa/drivers/dri" DESTDIR="${D}" install
			fi
			for x in "${ED}"/usr/$(get_libdir)/dri/*.so; do
				if [ -f ${x} -o -L ${x} ]; then
					mv -f "${x}" "${x/dri/mesa}" \
						|| die "Failed to move ${x}"
				fi
			done
			pushd "${ED}"/usr/$(get_libdir)/dri || die "pushd failed"
			ln -s ../mesa/*.so . || die "Creating symlink failed"
			# remove symlinks to drivers known to eselect
			for x in ${gallium_drivers[@]}; do
				if [ -f ${x} -o -L ${x} ]; then
					rm "${x}" || die "Failed to remove ${x}"
				fi
			done
			popd
		eend $?
	fi
	if use opencl; then
		if use gallium ; then
			ebegin "Moving Gallium/Clover OpenCL implementation for dynamic switching"
			local cl_dir="/usr/$(get_libdir)/OpenCL/vendors/mesa"
			dodir ${cl_dir}/{lib,include}
			if [ -f "${ED}/usr/$(get_libdir)/libOpenCL.so" ]; then
				mv -f "${ED}"/usr/$(get_libdir)/libOpenCL.so* \
				"${ED}"${cl_dir}
			fi
			if [ -f "${ED}/usr/include/CL/opencl.h" ]; then
				mv -f "${ED}"/usr/include/CL \
				"${ED}"${cl_dir}/include
			fi
			if [ ! -f "${ED}"${cl_dir}/lib/* ]; then
				einfo "No Gallium/Clover OpenCL driver, removing ICD config"
				rm -f "${ED}"/etc/OpenCL/vendors/mesa.icd
			fi
			eend $?
		fi
		if use beignet ; then
			ebegin "Installing Beignet Intel HD Graphics OpenCL implementation"
			cd "${BUILD_DIR}/beignet-${B_PV}"
			DESTDIR="${D}" ${CMAKE_MAKEFILE_GENERATOR} install "$@" || \
											die "Failed to install Beignet"
			insinto /usr/$(get_libdir)/OpenCL/vendors/beignet/include/CL
			doins include/CL/*
			eend $?
		fi
	fi

	if use openmax; then
		echo "XDG_DATA_DIRS=\"${EPREFIX}/usr/share/mesa/xdg\"" > "${T}/99mesaxdgomx"
		doenvd "${T}"/99mesaxdgomx
		keepdir /usr/share/mesa/xdg
	fi
}

multilib_src_install_all() {
	prune_libtool_files --all
	einstalldocs

	if use !bindist; then
		dodoc docs/patents.txt
	fi

	# Install config file for eselect mesa
	insinto /usr/share/mesa
	newins "${FILESDIR}/eselect-mesa.conf.10.1" eselect-mesa.conf
}

multilib_src_test() {
	if use llvm; then
		local llvm_tests='lp_test_arit lp_test_arit lp_test_blend lp_test_blend lp_test_conv lp_test_conv lp_test_format lp_test_format lp_test_printf lp_test_printf'
		pushd src/gallium/drivers/llvmpipe >/dev/null || die
		emake ${llvm_tests}
		pax-mark m ${llvm_tests}
		popd >/dev/null || die
	fi
	emake check
}

pkg_postinst() {
	# Switch to the xorg implementation.
	echo
	eselect opengl set --use-old ${OPENGL_DIR}

	# Select classic/gallium drivers
	if use classic || use gallium; then
		eselect mesa set --auto
	fi

	# Switch to mesa opencl
	if use opencl; then
		eselect opencl set --use-old ${PN}
	fi

	# run omxregister-bellagio to make the OpenMAX drivers known system-wide
	if use openmax; then
		ebegin "Registering OpenMAX drivers"
		BELLAGIO_SEARCH_PATH="${EPREFIX}/usr/$(get_libdir)/libomxil-bellagio0" \
			OMX_BELLAGIO_REGISTRY=${EPREFIX}/usr/share/mesa/xdg/.omxregister \
			omxregister-bellagio
		eend $?
	fi

	# warn about patent encumbered texture-float
	if use !bindist; then
		elog "USE=\"bindist\" was not set. Potentially patent encumbered code was"
		elog "enabled. Please see patents.txt for an explanation."
	fi

	if ! has_version media-libs/libtxc_dxtn; then
		elog "Note that in order to have full S3TC support, it is necessary to install"
		elog "media-libs/libtxc_dxtn as well. This may be necessary to get nice"
		elog "textures in some apps, and some others even require this to run."
	fi
}

pkg_prerm() {
	if use openmax; then
		rm "${EPREFIX}"/usr/share/mesa/xdg/.omxregister
	fi
}

# $1 - VIDEO_CARDS flag
# other args - names of DRI drivers to enable
# TODO: avoid code duplication for a more elegant implementation
driver_enable() {
	case $# in
		# for enabling unconditionally
		1)
			DRI_DRIVERS+=",$1"
			;;
		*)
			if use $1; then
				shift
				for i in $@; do
					DRI_DRIVERS+=",${i}"
				done
			fi
			;;
	esac
}

gallium_enable() {
	case $# in
		# for enabling unconditionally
		1)
			GALLIUM_DRIVERS+=",$1"
			;;
		*)
			if use $1; then
				shift
				for i in $@; do
					GALLIUM_DRIVERS+=",${i}"
				done
			fi
			;;
	esac
}
